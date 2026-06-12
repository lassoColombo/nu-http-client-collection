# Auto-generated client for MotaWord API v1.0
# Source: https://api.apis.guru/v2/specs/motaword.com/1.0/openapi.json
# Auth: --token flag or $env.MOTAWORD_API_TOKEN

const BASE_URL = "https://api.motaword.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o MOTAWORD_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://api.motaword.com" "https://sandbox.motaword.com" "http://localhost"] }
def auth-scheme-completer [] { ["basic" "bearer"] }

# Completers for enum parameters
def type-completer [] { ["active"] }
def type-filter-completer [] { ["ALL" "DESIGNS" "GLOSSARIES" "IMAGES" "LOCALIZATION" "PDFS" "PRESENTATIONS" "SPREADSHEETS" "STYLE_GUIDES" "SUBTITLES" "TEXT_DOCUMENTS" "WEB"] }
def order-by-completer [] { ["created_at" "id" "name" "updated_at"] }
def order-type-completer [] { ["asc" "desc"] }
def device-completer [] { ["Amazon" "Android" "Chrome" "Edge" "Firefox" "MacOS" "Safari" "Windows" "WindowsPhone" "iOS"] }
def type-completer-1 [] { ["OneSignal"] }
def order-by-completer-1 [] { ["delivery" "id" "price" "status"] }
def payment-method-completer [] { ["app" "client" "corporate" "corporate_card" "credit"] }
def accept-completer [] { ["application/json" "application/octet-stream"] }
def type-completer-2 [] { ["EMAIL" "INCOMING_EMAIL" "NOTE" "TASK"] }
def accept-completer-1 [] { ["application/json" "application/xml"] }
def period-completer [] { ["monthly" "weekly"] }
def user-type-completer [] { ["all" "vendor"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "static get" } } | get name | first)
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

# Available endpoints
#
# GET /
# operationId: getEndpoints
export def "static get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download result of an async operation
#
# GET /async/download
# operationId: downloadAsync
export def "async-download downloadAsync" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/async/download" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get blog posts - ordered by created desc by default
#
# GET /blogs
# operationId: getBlogPosts
export def "blogs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Article language, default `en`. When no blog article is available and `fallback=true` is specified, it falls back to `en`.
  --fallback: oneof<nothing, bool> # When `true`, and no article is found in the locale, it falls back to `locale=en`.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 1
]: nothing -> record<articles: table<announcement_type: string, author: string, content: string, created_at: string, excerpt: string, id: int, language: string, links: record, slug: string, title: string, topic: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "fallback" $fallback "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/blogs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear cache by key
#
# DELETE /cache/{key}
# operationId: deleteCache
export def "cache delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/cache/($key)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a commission list of current client.
#
# GET /commissions
# operationId: getCommissions
export def "commissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a commission list of current client.
#
# POST /commissions
# operationId: getCommissionsByFilter
export def "commissions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list # List of source language codes.
  --target-languages: list # List of target language codes.
  --users: list # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<commissions: table<amount: record, date: string, project: record, status: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/commissions")
  let body = {budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View continuous projects
#
# GET /continuous_projects
# operationId: getContinuousProjects
export def "continuous-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --type: string@type-completer # Type of continuous project. (nullable, default: active)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record, target_languages: list, type: string, word_count: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/continuous_projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a continuous project
#
# POST /continuous_projects
# operationId: createContinuousProject
# --subscription shape: {downgrade?: list, payment_method?: int, period_end?: string, plan_id?: string, plan_name?: string, price?: string, products?: list, schedule_name?: string, schedule_start?: string, subscription_id?: string, upgrade?: list, withTrial?: any}
export def "continuous-projects createContinuousProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --analytics-enabled: oneof<nothing, bool> # Should we collect analytics data from Active for this continuous project?
  --auto-start-postedit: oneof<nothing, bool> # Immediately start post-editing project for translation requests that are applied MT.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --id: int # format: int64
  --is-enabled: oneof<nothing, bool>
  --last-activity-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --links: any
  --mt-enabled: oneof<nothing, bool> # Immediately apply MT on translation requests if they are missing from TM.
  --mt-engine: string # One of "MOTAWORD", "GOOGLE", "AMAZON", "MS". Default is "MOTAWORD".
  --name: string
  --postedit-enabled: oneof<nothing, bool> # Get an instant quote for translation requests that are applied MT.
  --source-language: string
  --status: string # One of "a => ACTIVE", "i => INACTIVE", "d => DELETED", "c => SCHEDULED CANCELLATION", "p => SCHEDULED CHANGE"
  --subscription: record # shape: {downgrade?: list, payment_method?: int, period_end?: string, plan_id?: string, plan_name?: string, price?: string, products?: list, schedule_name?: string, schedule_start?: string, subscription_id?: string, upgrade?: list, withTrial?: any}
  --target-languages: list
  --type: string # Continuous project type. We currently have only 2 types, NULL and "active".
  --word-count: int # format: int64
]: any -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/continuous_projects")
  let body = {analytics_enabled: $analytics_enabled, auto_start_postedit: $auto_start_postedit, created_at: $created_at, id: $id, is_enabled: $is_enabled, last_activity_at: $last_activity_at, links: $links, mt_enabled: $mt_enabled, mt_engine: $mt_engine, name: $name, postedit_enabled: $postedit_enabled, source_language: $source_language, status: $status, subscription: $subscription, target_languages: $target_languages, type: $type, word_count: $word_count} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a continuous project
#
# DELETE /continuous_projects/{id}
# operationId: deleteContinuousProject
export def "continuous-projects delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a continuous project
#
# GET /continuous_projects/{id}
# operationId: getContinuousProject
export def "continuous-projects get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a continuous project
#
# POST /continuous_projects/{id}
# operationId: updateContinuousProject
# --languages item shape: {code?: string, is_enabled?: bool}
export def "continuous-projects updateContinuousProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --analytics-enabled: oneof<nothing, bool>
  --auto-start-postedit: oneof<nothing, bool>
  --is-enabled: oneof<nothing, bool>
  --languages: list # item shape: {code?: string, is_enabled?: bool}
  --mt-enabled: oneof<nothing, bool>
  --name: string
  --postedit-enabled: oneof<nothing, bool>
]: any -> record<analytics_enabled: bool, auto_start_postedit: bool, created_at: string, id: int, is_enabled: bool, last_activity_at: string, links: record<self: record<href: string>, editors: record>, mt_enabled: bool, mt_engine: string, name: string, postedit_enabled: bool, source_language: string, status: string, subscription: record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any>, target_languages: list<string>, type: string, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)")
  let body = {analytics_enabled: $analytics_enabled, auto_start_postedit: $auto_start_postedit, is_enabled: $is_enabled, languages: $languages, mt_enabled: $mt_enabled, name: $name, postedit_enabled: $postedit_enabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get JWT token to be used in analytics dashboards
#
# GET /continuous_projects/{id}/analytics-token
# operationId: getAnalyticsToken
export def "continuous-projects-analytics-token get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<jwt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/analytics-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save/collect analytics data from Active widget
#
# POST /continuous_projects/{id}/collect-analytics
# operationId: collectAnalytics
export def "continuous-projects-collect-analytics collectAnalytics" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --anonymousId: string
  --properties: record
  --sessionId: string
  --type: string
  --userId: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/collect-analytics")
  let body = {anonymousId: $anonymousId, properties: $properties, sessionId: $sessionId, type: $type, userId: $userId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete continuous project
#
# POST /continuous_projects/{id}/complete
# operationId: complete
export def "continuous-projects-complete complete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get quote for documents
#
# POST /continuous_projects/{id}/documents/quote
# operationId: getQuoteForDocuments
export def "continuous-projects-documents-quote post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --files: list
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/documents/quote")
  let body = {files: $files} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/complete
# operationId: completeContinuousDocument
export def "continuous-projects-documents-complete completeContinuousDocument" [
  id: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/documents/($documentId)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a quote for a continuous project document
#
# POST /continuous_projects/{id}/documents/{documentId}/quote
# operationId: getQuoteForDocument
export def "continuous-projects-documents-quote post-by-id-documentId" [
  id: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/documents/($documentId)/quote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get quote for languages
#
# POST /continuous_projects/{id}/languages/quote
# operationId: getQuoteForLanguages
export def "continuous-projects-languages-quote post-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --languages: list
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/languages/quote")
  let body = {languages: $languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Complete continuous project language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/complete
# operationId: completeLanguage
export def "continuous-projects-languages-complete completeLanguage" [
  id: int
  targetLanguage: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/languages/($targetLanguage)/complete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get quote for language
#
# POST /continuous_projects/{id}/languages/{targetLanguage}/quote
# operationId: getQuoteForLanguage
export def "continuous-projects-languages-quote post-by-id-targetLanguage" [
  id: int
  targetLanguage: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/languages/($targetLanguage)/quote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete subscription for continuous project
#
# DELETE /continuous_projects/{id}/subscription
# operationId: deleteSubscription
export def "continuous-projects-subscription delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get subscription for continuous project
#
# GET /continuous_projects/{id}/subscription
# operationId: getSubscription
export def "continuous-projects-subscription get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/subscription")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create subscription for continuous project
#
# POST /continuous_projects/{id}/subscription
# operationId: createSubscription
export def "continuous-projects-subscription createSubscription" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --downgrade: list # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list # Stripe upgradable plan
  --withTrial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/subscription")
  let body = {downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, withTrial: $withTrial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update subscription for continuous project
#
# PUT /continuous_projects/{id}/subscription
# operationId: updateSubscription
export def "continuous-projects-subscription updateSubscription" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --downgrade: list # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list # Stripe upgradable plan
  --withTrial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/subscription")
  let body = {downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, withTrial: $withTrial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update subscription payment method for continuous project
#
# PUT /continuous_projects/{id}/subscription/payment
# operationId: updateSubscriptionPaymentMethod
export def "continuous-projects-subscription-payment updateSubscriptionPaymentMethod" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --downgrade: list # Stripe downgradable plan
  --payment-method: int # Stripe subscription plan payment card internal id
  --period-end: string # Stripe plan period end (format: date-time)
  --plan-id: string # Stripe subscription plan id
  --plan-name: string # Stripe subscription plan name
  --price: string # Stripe plan price
  --products: list
  --schedule-name: string # Stripe Scheduled plan period end
  --schedule-start: string # Stripe Scheduled start date (format: date-time)
  --subscription-id: string # Stripe subscription id for this project
  --upgrade: list # Stripe upgradable plan
  --withTrial: any # Stripe plan trial (format: boolean)
]: any -> record<downgrade: list<string>, payment_method: int, period_end: string, plan_id: string, plan_name: string, price: string, products: list<any>, schedule_name: string, schedule_start: string, subscription_id: string, upgrade: list<string>, withTrial: any> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/subscription/payment")
  let body = {downgrade: $downgrade, payment_method: $payment_method, period_end: $period_end, plan_id: $plan_id, plan_name: $plan_name, price: $price, products: $products, schedule_name: $schedule_name, schedule_start: $schedule_start, subscription_id: $subscription_id, upgrade: $upgrade, withTrial: $withTrial} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Instantly translate your content
#
# POST /continuous_projects/{id}/translate/{targetLanguage}
# operationId: translate
# --documents item shape: {data?: string, name?: string}
# --filters shape: {skipMt?: list, skipPostEdit?: list}
export def "continuous-projects-translate translate" [
  id: int
  targetLanguage: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list # Simple list of strings to be translated. You can also choose to upload files instead of strings.
  --documents: list # You can add as many files as you want in documents parameter. — item shape: {data?: string, name?: string}
  --filters: record # shape: {skipMt?: list, skipPostEdit?: list}
  --meta: record # Free-form meta data to attach to your instant translation request. This can be used in statistics and analytical dashboards.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($id)/translate/($targetLanguage)")
  let body = {contents: $contents, documents: $documents, filters: $filters, meta: $meta} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View continuous documents
#
# GET /continuous_projects/{projectId}/documents
# operationId: getContinuousProjectDocuments
export def "continuous-projects-documents list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterByLanguage: string
]: nothing -> record<documents: table<billed_word_count: int, id: string, links: record, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterByLanguage" $filterByLanguage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new document to your continuous project
#
# POST /continuous_projects/{projectId}/documents
# operationId: addDocument
# --document shape: {data?: string, name?: string}
export def "continuous-projects-documents addDocument" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents")
  let body = {document: $document} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get continuous project document progress for multiple IDs
#
# POST /continuous_projects/{projectId}/documents/progress
# operationId: postContinuousProjectDocumentProgress
export def "continuous-projects-documents-progress post" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentName: string
  --filterByLanguage: string
]: any -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/progress")
  let body = {documentName: $documentName, filterByLanguage: $filterByLanguage} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of strings and its translations in the project.
#
# POST /continuous_projects/{projectId}/documents/strings
# operationId: postContinuousProjectFileStrings
export def "continuous-projects-documents-strings post" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documentName: string
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/strings")
  let body = {documentName: $documentName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}
# operationId: getContinuousProjectDocument
export def "continuous-projects-documents get" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the document
#
# POST /continuous_projects/{projectId}/documents/{documentId}
# operationId: updateDocument
# --document shape: {data?: string, name?: string}
export def "continuous-projects-documents updateDocument" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --document: record # shape: {data?: string, name?: string}
]: any -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/($documentId)")
  let body = {document: $document} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Monitor progress of a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/progress
# operationId: getContinuousProjectDocumentProgress
export def "continuous-projects-documents-progress get" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterByLanguage: string
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterByLanguage" $filterByLanguage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/($documentId)/progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View strings their translations in a continuous document
#
# GET /continuous_projects/{projectId}/documents/{documentId}/strings
# operationId: getContinuousProjectFileStrings
export def "continuous-projects-documents-strings get" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/documents/($documentId)/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Invoices of a continuous project
#
# GET /continuous_projects/{projectId}/invoices
# operationId: getContinuousProjectInvoices
export def "continuous-projects-invoices get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<invoices: table<amount: float, base_amount: float, base_currency: string, billing: record, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/invoices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Monitor progress and status of a continous project
#
# GET /continuous_projects/{projectId}/progress
# operationId: getContinuousProjectProgress
export def "continuous-projects-progress get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filterByLanguage: string
]: nothing -> record<costs: record<mt: record<amount: float, currency: string>, post_edit: record<amount: float, currency: string>, saved: record<amount: float, currency: string>, total: record<amount: float, currency: string>>, progress: record<languages: record, links: record<self: record, project: record>, project_status: string, proofreading: float, total: float, translation: float, word_count: int>, word_counts: record<mt: int, post_edit: int, total: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filterByLanguage" $filterByLanguage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View strings and translations in continuous project
#
# GET /continuous_projects/{projectId}/strings
# operationId: getContinuousProjectStrings
export def "continuous-projects-strings get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear translation cache
#
# DELETE /continuous_projects/{projectId}/strings/cached
# operationId: clearTranslationCache
export def "continuous-projects-strings-cached clearTranslationCache" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/strings/cached" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View cached strings translations in continuous project
#
# GET /continuous_projects/{projectId}/strings/cached
# operationId: getTranslationCache
export def "continuous-projects-strings-cached get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --flatten: oneof<nothing, bool> # Flatten cache results and ignore document keys (default: 1)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "flatten" $flatten "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/strings/cached" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recache translations
#
# POST /continuous_projects/{projectId}/strings/recache-tms
# operationId: recacheTranslations
export def "continuous-projects-strings-recache-tms recacheTranslations" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # Locale
  --file-id: int # Continuous Project File ID (format: int64)
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "locale" $locale "scalar") (serialize-qp "file_id" $file_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/continuous_projects/($projectId)/strings/recache-tms" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View Active widgets
#
# GET /continuous_projects/{projectId}/widgets
# operationId: getActiveWidgets
export def "continuous-projects-widgets list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, widgets: table<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Active widget
#
# POST /continuous_projects/{projectId}/widgets
# operationId: createActiveWidget
export def "continuous-projects-widgets createActiveWidget" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --body-variables: string # Continuous project variable definitions
]: any -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets")
  let body = {allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a single widget for this Active project
#
# DELETE /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: deleteActiveWidget
export def "continuous-projects-widgets delete" [
  projectId: int
  widgetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets/($widgetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View an Active widget
#
# GET /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: getActiveWidget
export def "continuous-projects-widgets get" [
  projectId: int
  widgetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets/($widgetId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Active widget settings.
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}
# operationId: updateActiveWidget
export def "continuous-projects-widgets updateActiveWidget" [
  projectId: int
  widgetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --body-variables: string # Continuous project variable definitions
]: any -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets/($widgetId)")
  let body = {allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Active widget token
#
# POST /continuous_projects/{projectId}/widgets/{widgetId}/reset-token
# operationId: resetActiveWidgetToken
export def "continuous-projects-widgets-reset-token resetActiveWidgetToken" [
  projectId: int
  widgetId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<allow_hash_in_url: bool, allow_query_in_url: bool, auto_detect_source_language: bool, created_at: string, elements: string, follow_user: bool, force_cache_refresh_interval: bool, id: int, language_mappings: string, live: bool, modify_links: bool, name: string, optimize_per_page: bool, pages: string, path_regex: string, position: string, query_name: string, reboot_on_url_change: bool, restricted_domains: string, sections: string, test_mode: bool, theme: string, token: string, url_change_mode: string, url_mode: string, use_cache: bool, use_dummy_translations: bool, variables: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/continuous_projects/($projectId)/widgets/($widgetId)/reset-token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your corporate account
#
# GET /corporate
# operationId: getCorporate
export def "corporate get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View available permissions
#
# GET /corporate/permissions
# operationId: getAvailableCorporatePermissions
export def "corporate-permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View user groups
#
# GET /corporate/user-groups
# operationId: getCorporateUserGroups
export def "corporate-user-groups get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a corporate user group
#
# POST /corporate/user-groups
# operationId: saveCorporateUserGroup
export def "corporate-user-groups saveCorporateUserGroup" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporate-id: int # format: int64
  --id: int # format: int64
  --name: string
  --permissions: list
]: any -> record<corporate_id: int, id: int, name: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/user-groups")
  let body = {corporate_id: $corporate_id, id: $id, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View users
#
# GET /corporate/users
# operationId: getCorporateUsers
export def "corporate-users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a user
#
# POST /corporate/users
# operationId: saveCorporateUser
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "corporate-users saveCorporateUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporate/users")
  let body = {city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of corporate accounts
#
# GET /corporates/all
# operationId: getCorporatesList
export def "corporates-all get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/corporates/all")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get details of this corporate account
#
# GET /corporates/{corporateId}
# operationId: getCorporateById
export def "corporates get" [
  corporateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, domain: string, email: string, id: int, logo: string, name: string, web_site: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporates/($corporateId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of available permissions for this corporate account. They are used when assigning permissions to corporate users.
#
# GET /corporates/{corporateId}/permissions
# operationId: getAvailableCorporatePermissionsById
export def "corporates-permissions get" [
  corporateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporates/($corporateId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of user groups for this corporate account
#
# GET /corporates/{corporateId}/user-groups
# operationId: getCorporateUserGroupsById
export def "corporates-user-groups get" [
  corporateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporates/($corporateId)/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update a corporate user group for this corporate account
#
# POST /corporates/{corporateId}/user-groups
# operationId: saveCorporateUserGroupById
export def "corporates-user-groups saveCorporateUserGroupById" [
  corporateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --corporate-id: int # format: int64
  --id: int # format: int64
  --name: string
  --permissions: list
]: any -> record<corporate_id: int, id: int, name: string, permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporates/($corporateId)/user-groups")
  let body = {corporate_id: $corporate_id, id: $id, name: $name, permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of users for this corporate account
#
# GET /corporates/{corporateId}/users
# operationId: getCorporateUsersById
export def "corporates-users get" [
  corporateId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/corporates/($corporateId)/users")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete your account
#
# DELETE /delete-account
# operationId: deleteAccount
export def "delete-account delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/delete-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your documents
#
# GET /documents
# operationId: getDocuments
export def "documents get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recent" $recent "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type_filter" $type_filter "scalar") (serialize-qp "language_code" $language_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of subjects of projects
#
# GET /documents/subjects
# operationId: getAllDocumentSubjects
export def "documents-subjects get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents/subjects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a single document
#
# GET /documents/{documentId}
# operationId: getDocument
export def "documents get-by-documentId" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billed_word_count: int, id: string, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, post_edit_enabled: bool, project_id: string, source_language: string, target_languages: list<string>, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a document translation progress
#
# GET /documents/{documentId}/progress
# operationId: getDocumentProgress
export def "documents-progress get" [
  documentId: float
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($documentId)/progress")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Regenerate preview and return preview URL for given file
#
# POST /documents/{documentId}/regenerate_preview
# operationId: regeneratePreview
export def "documents-regenerate-preview regeneratePreview" [
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<link: record<href: string>, source: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($documentId)/regenerate_preview")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Find documents similar to this document.
#
# GET /documents/{documentId}/similars
# operationId: getSimilarDocuments
export def "documents-similars get" [
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --per-page: int # Determines the number of similar documents to return. (format: int64, default: 1)
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "per_page" $per_page "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/documents/($documentId)/similars" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Use the translation of given source manual document as manual draft source for the given target document.
#
# POST /documents/{documentId}/use_as_draft
# operationId: useAsDraft
export def "documents-use-as-draft useAsDraft" [
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fromFileId: float
  --fromManualTranslationFileId: float
  --toManualTranslationFileId: float
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($documentId)/use_as_draft")
  let body = {fromFileId: $fromFileId, fromManualTranslationFileId: $fromManualTranslationFileId, toManualTranslationFileId: $toManualTranslationFileId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Use the translation of the given manual document as a regular file.
#
# POST /documents/{documentId}/use_as_regular
# operationId: useAsRegular
export def "documents-use-as-regular useAsRegular" [
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allowOriginalFilePreview: oneof<nothing, bool>
  --allowReviewInManualEditor: oneof<nothing, bool>
  --disableInvitations: oneof<nothing, bool>
  --fromManualTranslationFileId: float
  --hideNumbers: oneof<nothing, bool>
  --recreate: oneof<nothing, bool>
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($documentId)/use_as_regular")
  let body = {allowOriginalFilePreview: $allowOriginalFilePreview, allowReviewInManualEditor: $allowReviewInManualEditor, disableInvitations: $disableInvitations, fromManualTranslationFileId: $fromManualTranslationFileId, hideNumbers: $hideNumbers, recreate: $recreate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /downgrade-proofreader
#
# operationId: downgradeProofreader
export def "downgrade-proofreader downgradeProofreader" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/downgrade-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your vendor earnings
#
# GET /earnings
# operationId: getEarnings
export def "earnings list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/earnings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of supported file formats
#
# GET /formats
# operationId: getFormats
export def "formats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/formats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Freeze account
#
# POST /freeze-account
# operationId: freezeAccount
export def "freeze-account freezeAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/freeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download account glossary.
#
# GET /glossary
# operationId: downloadGlobalGlossary
export def "glossary downloadGlobalGlossary" [
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
  let full_url = (build-url $base "/glossary")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update the account glossary
#
# POST /glossary
# operationId: updateGlobalGlossary
export def "glossary updateGlobalGlossary" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  glossary: string # Glossary file. Currently supported formats: .xlsx, .tbx (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/glossary")
  let body = {glossary: $glossary} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a new access token for MotaWord's integrations service
#
# GET /integrations/token
# operationId: getIntegrationsToken
export def "integrations-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/integrations/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get vendor list for compiled invitation needs
#
# POST /invitation/vendors
# operationId: getInvitationVendors
export def "invitation-vendors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> record<vendors: table<matchedNeeds: list, userId: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/invitation/vendors")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List of supported languages
#
# GET /languages
# operationId: getLanguages
export def "languages get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/languages")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Log user's current location. This data is used in our Intelligent Project Manager for various data analysis, including project prioritization for vendors and account validation.
#
# POST /location
# operationId: logLocation
export def "location logLocation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  lat: float # Latitude of location (format: float)
  lon: float # Longitude of location (format: float)
  --timestamp: int
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/location")
  let body = {lat: $lat, lon: $lon, timestamp: $timestamp} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /make-proofreader
#
# operationId: makeProofreader
export def "make-proofreader makeProofreader" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/make-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your account info
#
# GET /me
# operationId: getMe
export def "me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update your account info
#
# POST /me
# operationId: updateMe
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "me updateMe" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/me")
  let body = {city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a delivery prediction for a project
#
# POST /ml/delivery-prediction
# operationId: getDeliveryPrediction
export def "ml-delivery-prediction post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --projectId: int # format: int64
]: any -> record<result: table<language: string, late: bool, probability: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ml/delivery-prediction")
  let body = {projectId: $projectId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Subscribe to push notifications
#
# POST /notifications/subscribe
# operationId: subscribeNotification
export def "notifications-subscribe subscribeNotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/subscribe")
  let body = {device: $device, endpoint: $endpoint, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /notifications/unsubscribe
#
# operationId: unsubscribeNotification
export def "notifications-unsubscribe unsubscribeNotification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/notifications/unsubscribe")
  let body = {device: $device, endpoint: $endpoint, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends a message to chat
#
# POST /pam/chat
# operationId: postMessage
export def "pam-chat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --message: string # the message to be sent
  --recipients: list # name of the recipients in the channel
  --slots: list # contexts for next message
  --thread-id: string # id of the thread
  --thread-key: string # the key for thread_id default is project
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/pam/chat")
  let body = {message: $message, recipients: $recipients, slots: $slots, thread_id: $thread_id, thread_key: $thread_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the Pam profile of a client for this client ID
#
# GET /pam/profiles/client/{clientId}
# operationId: getClientProfileForPam
export def "pam-profiles-client get" [
  clientId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<account_creation_date: string, client_project_count: float, corporate: string, corporate_id: float, corporate_user_count: float, frequent_file_extension: string, frequent_language_pairs: list<string>, full_name: string, growth: bool, is_complex: bool, last_12_months_spending: float, last_project: float, last_project_time: string, last_proofreaders: table<full_name: string, id: float, language: string, vendor_link: string>, notes: list<string>, nps: record<average: record<completed_surveys_count: float, score: float>, last: record<completion_date: string, score: float>>, user_rank_in_project_count: float, user_rank_in_spending: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pam/profiles/client/($clientId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get completion report data of a project
#
# GET /pam/projects/{projectId}/completion-report
# operationId: getProjectCompletionReportForPam
export def "pam-projects-completion-report get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<admin_user_id: float, completion_report_data: table<invited_vendors: list, target_language: string>, id: float, quote_id: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/pam/projects/($projectId)/completion-report")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update your account password
#
# POST /password
# operationId: updatePassword
export def "password updatePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --password: string # New Password
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/password")
  let body = {password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View your payment and billing info
#
# GET /payment
# operationId: getPaymentInfo
export def "payment get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update payment info
#
# POST /payment
# operationId: updatePaymentInfo
export def "payment updatePaymentInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --bin: string
  --save-as-corporate-primary: oneof<nothing, bool>
  --share-with-corporate-users: oneof<nothing, bool>
  --stripeToken: string
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment")
  let body = {city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, bin: $bin, save_as_corporate_primary: $save_as_corporate_primary, share_with_corporate_users: $share_with_corporate_users, stripeToken: $stripeToken} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset payment code
#
# POST /payment/reset-corporate-payment-code
# operationId: resetCorporatePaymentCode
export def "payment-reset-corporate-payment-code resetCorporatePaymentCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/reset-corporate-payment-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Manage automatic charges on your credit card
#
# POST /payment/toggle-corporate-auto-charge
# operationId: toggleCorporateAutoCharge
export def "payment-toggle-corporate-auto-charge toggleCorporateAutoCharge" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payment/toggle-corporate-auto-charge")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View saved credit card
#
# GET /payment/{cardId}
# operationId: getCreditCard
export def "payment get-by-cardId" [
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment/($cardId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete credit card
#
# DELETE /payment/{cardId}/delete
# operationId: deleteCreditCard
export def "payment-delete delete" [
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment/($cardId)/delete")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reset credit card payment code
#
# POST /payment/{cardId}/reset-payment-code
# operationId: resetCardPaymentCode
export def "payment-reset-payment-code resetCardPaymentCode" [
  cardId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bin: string, id: int, is_default: bool, payment_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payment/($cardId)/reset-payment-code")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your permissions
#
# GET /permissions
# operationId: getPermissions
export def "permissions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload profile picture
#
# POST /profile-picture
# operationId: uploadProfilePicture
export def "profile-picture uploadProfilePicture" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/profile-picture")
  let body = {profile_picture: $profile_picture} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View your translation projects
#
# GET /projects
# operationId: getProjects
@deprecated --flag with-pending
@deprecated --flag with-started
@deprecated --flag with-completed
export def "projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --status: list # Filter projects by status. Accepts multiple statuses. Possible values 'pending', 'started', 'completed'
  --with-pending: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-started: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --with-completed: oneof<nothing, bool> # deprecated. use `status[]` param. (DEPRECATED, default: true)
  --order-by: string@order-by-completer-1 # default: id
  --order-type: string@order-type-completer
  --with: list # Include detailed information. Possible values 'client', 'vendor'
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "status[]" $status "multi") (serialize-qp "with_pending" $with_pending "scalar") (serialize-qp "with_started" $with_started "scalar") (serialize-qp "with_completed" $with_completed "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar") (serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/projects" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new project
#
# POST /projects
# operationId: createProject
export def "projects createProject" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value.
  --documents: string # Optional. You can add as many files as you want in documents[] parameter. Or you add your documents later in separate calls. (format: binary)
  --glossaries: string # Optional. Only one glossary is supported at the moment. (format: binary)
  --source-language: string
  --styleguides: string # Optional. You can add as many files as you want in styleguides[] parameter. Or you add your style guides later in separate calls. (format: binary)
  --target-languages: list
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/projects")
  let body = {callback_url: $callback_url, coupon_code: $coupon_code, custom: $custom, documents[]: $documents, glossaries[]: $glossaries, source_language: $source_language, styleguides[]: $styleguides, target_languages[]: $target_languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Quote Id
#
# GET /projects/from-internal-id/{projectId}
# operationId: getQuoteIdFromInternalId
export def "projects-from-internal-id get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<internal_id: int, public_id: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/from-internal-id/($projectId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List projects as a vendor
#
# GET /projects/vendor
# operationId: getVendorProjects
export def "projects-vendor list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "joined" $joined "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/projects/vendor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete your translation project
#
# DELETE /projects/{id}
# operationId: deleteProject
export def "projects delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a translation project
#
# GET /projects/{id}
# operationId: getProject
export def "projects get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Include detailed information. Possible values 'client', 'vendor', 'score'
]: nothing -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project info and settings
#
# PUT /projects/{id}
# operationId: updateProject
export def "projects updateProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Optional. If you provide a callback URL, we will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
  --coupon-code: string # Coupon code to redeem
  --custom: list # Optional. This is a consistent custom data parameter that will be given to you in the response across every request of this project model. Values should be provided like this, custom[my_key] = my_value. If you previously provided one, it will be replaced.
  --source-language: string
  --target-languages: list
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)")
  let body = {callback_url: $callback_url, coupon_code: $coupon_code, custom: $custom, source_language: $source_language, target_languages[]: $target_languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Assign a CM to the project
#
# POST /projects/{id}/assign-cm
# operationId: assignCM
export def "projects-assign-cm assignCM" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-id: int # format: int64
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/assign-cm")
  let body = {user_id: $user_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Trigger a call to your callback URL related to this project.
#
# GET /projects/{id}/callback/{actionType}
# operationId: triggerCallback
export def "projects-callback triggerCallback" [
  id: int
  actionType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list<record>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record, documents: record, glossaries: record, payment: record, quote_pdf: record, styleguides: record>, pairs: list<record>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>>, result: string, type: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/callback/($actionType)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel your translation project
#
# POST /projects/{id}/cancel
# operationId: cancelProject
export def "projects-cancel cancelProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Cancellation reason
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/cancel")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deliver project
#
# POST /projects/{id}/deliver
# operationId: deliverProject
export def "projects-deliver deliverProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/deliver")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download your translated project
#
# GET /projects/{id}/download
# operationId: download
export def "projects-download download" [
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
  let full_url = (build-url $base $"/projects/($id)/download")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download your translated project language
#
# GET /projects/{id}/download/{language}
# operationId: downloadLanguage
export def "projects-download downloadLanguage" [
  id: int
  language: string
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
  let full_url = (build-url $base $"/projects/($id)/download/($language)")
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send a quote email
#
# POST /projects/{id}/email-quote
# operationId: sendQuoteEmail
export def "projects-email-quote sendQuoteEmail" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/email-quote")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project invoice
#
# GET /projects/{id}/invoice
# operationId: getInvoice
export def "projects-invoice get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<amount: float, base_amount: float, base_currency: string, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, currency: string, id: int, invoice_no: int, invoiced_at: string, links: record<self: record<href: string>, corporate: record<href: string>, html: record<href: string>, json: record<href: string>, pdf: record<href: string>, project: record<href: string>, view: record<href: string>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/invoice")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download project invoice (HTML)
#
# GET /projects/{id}/invoice.html
# operationId: downloadHtmlInvoice
export def "projects-invoicehtml downloadHtmlInvoice" [
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
  let full_url = (build-url $base $"/projects/($id)/invoice.html")
  let accept_val = "text/html"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download project invoice (PDF)
#
# GET /projects/{id}/invoice.pdf
# operationId: downloadPdfInvoice
export def "projects-invoicepdf downloadPdfInvoice" [
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
  let full_url = (build-url $base $"/projects/($id)/invoice.pdf")
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Launch your translation project
#
# POST /projects/{id}/launch
# operationId: launchProject
export def "projects-launch launchProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --bin: string # Last 4 digits of the credit card you are using one-time. This parameter is only required when stripe_token is provided.
  --budget-code: string # Optional with corporate accounts. Not available for others.
  --card-id: int # Optional. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. (format: int64)
  --payment-code: string # Optional. `corporate` payment method requires this.s
  --payment-method: string@payment-method-completer # Optional. Determines which method to use for payment. `client`, `app`, `corporate_card` methods require a credit card ID. `credit` method requires Stripe token and bin. `corporate` method follows corporate account policy automatically, either follows invoicing flow or automatically charges corporate's primary card.
  --stripe-token: string # This is required if you are using a one-time credit card. This is the token generted from frontend via Stripe SDK. If you are using a one-time card with `stripe_token`, you must also provide `bin`, last 4 digits of the card.
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/launch")
  let body = {bin: $bin, budget_code: $budget_code, card_id: $card_id, payment_code: $payment_code, payment_method: $payment_method, stripe_token: $stripe_token} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Package your translated project
#
# POST /projects/{id}/package
# operationId: package
export def "projects-package package" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/package" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Track translation packaging status
#
# GET /projects/{id}/package/check
# operationId: trackPackage
export def "projects-package-check trackPackage" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --key: string # This is the package tracking key provided in the response of a /package call.
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "key" $key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/package/check" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Package your translated project language
#
# POST /projects/{id}/package/{language}
# operationId: packageLanguage
export def "projects-package packageLanguage" [
  id: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --async: int # If you want to package and download the translation synchronously, mark this parameter as '0'. It will package the translation and then return the packaged file in the response, identical to /download call after an asynchronous /package call. (format: int64, default: 0)
]: nothing -> record<status: string, key: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/package/($language)" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View progress of a project
#
# GET /projects/{id}/progress
# operationId: getProgress
export def "projects-progress get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-raw: oneof<nothing, bool> # This will return a more raw progress information for translation and proofreading. For instance, when completed, we will return 100% for both tasks by default, whereas their actual progress may be lower than 100%. (default: false)
]: nothing -> record<languages: record, links: record<self: record<href: string>, project: record<href: string>>, project_status: string, proofreading: float, total: float, translation: float, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "raw" $qp_raw "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/progress" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Recreate your translation project from scratch. This is a risky action, you will lose current translations.
#
# POST /projects/{id}/recreate
# operationId: recreateProject
export def "projects-recreate recreateProject" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/recreate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit feedback report for a project
#
# POST /projects/{id}/reports
# operationId: submitProjectReports
export def "projects-reports submitProjectReports" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --activity-type: string # Activity Type
  --message: string # Report Message
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/reports")
  let body = {activity_type: $activity_type, message: $message} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sales activities for a project
#
# GET /projects/{id}/sales/activities
# operationId: getSalesActivities
export def "projects-sales-activities get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --excludeOwner: string
  --type: string@type-completer-2
]: nothing -> record<activities: table<body: string, created_at: int, created_by: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "excludeOwner" $excludeOwner "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($id)/sales/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert sales activity for a project
#
# POST /projects/{id}/sales/activities
# operationId: insertSalesActivity
export def "projects-sales-activities insertSalesActivity" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --subject: string
  --timestamp: int # format: int64
  --type: string # Activity Type
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/sales/activities")
  let body = {subject: $subject, timestamp: $timestamp, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete project webhooks
#
# DELETE /projects/{id}/webhooks
# operationId: deleteProjectWebhook
export def "projects-webhooks delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project webhooks
#
# GET /projects/{id}/webhooks
# operationId: getProjectWebhooks
export def "projects-webhooks get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update project webhook
#
# POST /projects/{id}/webhooks
# operationId: postProjectWebhook
export def "projects-webhooks post" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/webhooks")
  let body = {callback_url: $callback_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update project webhook
#
# PUT /projects/{id}/webhooks
# operationId: updateProjectWebhook
export def "projects-webhooks updateProjectWebhook" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --callback-url: string # Webhook URL. We will send POST callbacks when the status of the current project is changed. Possible status changes are, 'translated', 'proofread', 'completed'.
]: any -> record<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list<record>, last_name: string, last_seen_online_at: int, links: record<self: record, login_as: record, projects: record, responsivity: record, stats: record>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list<record>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record, require_1099: bool, tags: list, tms_user_name: string, vendor_type: string>, zip_code: string>, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: table<code: string, help: string, http_code: int, message: string>, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record<self: record<href: string>, documents: record<href: string>, glossaries: record<href: string>, payment: record<href: string>, quote_pdf: record<href: string>, styleguides: record<href: string>>, pairs: table<currency: string, is_proofreader: bool, proofreader: record, proofreading_rate: float, source_language: string, target_language: string, translation_rate: float>, pivoted_projects: list<int>, price: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, price_without_discount: record<amount: float, base_amount: float, base_currency: string, currency: string, usd_amount: float>, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list<string>, target_languages: list<string>, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record<base: float, duplicate: float, exclusion: float, final: float, tm: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($id)/webhooks")
  let body = {callback_url: $callback_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Monitor project activities
#
# GET /projects/{projectId}/activities
# operationId: getActivities
export def "projects-activities list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<activities: table<activity_at: int, id: int, links: record, source_text: string, target_text: string, translator: int, type: string>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/activities" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View an activity
#
# GET /projects/{projectId}/activities/{activityId}
# operationId: getActivity
export def "projects-activities get" [
  projectId: int
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activity_at: int, id: int, links: record<self: record<href: string>, comments: record<href: string>, project: record<href: string>>, source_text: string, target_text: string, translator: int, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/activities/($activityId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Submit comment to an activity
#
# POST /projects/{projectId}/activities/{activityId}
# operationId: submitComment
export def "projects-activities submitComment" [
  projectId: int
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  comment: string # Comment text.
  --commented-at: int # Unix epoch time (format: int64)
  --id: int # format: int64
  --links: any
]: any -> record<comment: string, commented_at: int, id: int, links: record<self: record<href: string>, activity: record<href: string>, project: record<href: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/activities/($activityId)")
  let body = {comment: $comment, commented_at: $commented_at, id: $id, links: $links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View activity comments
#
# GET /projects/{projectId}/activities/{activityId}/comments
# operationId: getActivityComments
export def "projects-activities-comments get" [
  projectId: int
  activityId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/activities/($activityId)/comments")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View all project comments
#
# GET /projects/{projectId}/comments
# operationId: getComments
export def "projects-comments get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<activities: table<comment: string, commented_at: int, id: int, links: record>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/comments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project source documents
#
# GET /projects/{projectId}/documents
# operationId: getProjectDocuments
export def "projects-documents list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a new document
#
# POST /projects/{projectId}/documents
# operationId: createProjectDocument
# --source-links[] item shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
export def "projects-documents createProjectDocument" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: list # You can add as many files as you want in documents[] parameter.
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-links: list # When provided, we will download the files from these URLs, in addition to files provded in `documents` parameter and then save as source documents — item shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/documents")
  let body = {documents[]: $documents, schemes[]: $schemes, source-links[]: $source_links} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the document
#
# DELETE /projects/{projectId}/documents/{documentId}
# operationId: deleteProjectDocument
export def "projects-documents delete" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a project source document
#
# GET /projects/{projectId}/documents/{documentId}
# operationId: getProjectDocument
export def "projects-documents get" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update the document.
#
# POST /projects/{projectId}/documents/{documentId}
# operationId: updateProjectDocument
# --source-link shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
export def "projects-documents updateProjectDocument" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --documents: string # Single file data. The name is plural to provide a consistent naming convention. (format: binary)
  --schemes: string # JSON string. If your documents have a scheme, as in cases of CSV files, use the same array index keys for `schemes` parameter to specify their schemes. See `Document Schemes` title in the API documentation.
  --source-link: record # shape: {name?: string, size?: int, source?: "dropbox"|"googledrive"|"icloud", url?: string}
]: any -> record<file_type: string, has_custom_package: bool, id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, manual_files: table<driveFileId: int, isProofread: bool, isTranslated: bool, language: string, proofreadingFileId: int, translationFileId: int>, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list<string>, uploaded_at: int, word_count: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)")
  let body = {documents: $documents, schemes: $schemes, source-link: $source_link} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a project source document
#
# GET /projects/{projectId}/documents/{documentId}/download
# operationId: downloadProjectDocument
export def "projects-documents-download downloadProjectDocument" [
  projectId: int
  documentId: int
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
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View strings and translations of a document
#
# GET /projects/{projectId}/documents/{documentId}/translations
# operationId: getDocumentTranslations
export def "projects-documents-translations list" [
  projectId: int
  documentId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)/translations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download translated document
#
# GET /projects/{projectId}/documents/{documentId}/translations/download/{language}
# operationId: downloadTranslatedDocumentForLanguage
export def "projects-documents-translations-download downloadTranslatedDocumentForLanguage" [
  projectId: int
  documentId: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --certified: oneof<nothing, bool> # Download certified translation (default: 0)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certified" $certified "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)/translations/download/($language)" $qp)
  let accept_val = "application/octet-stream"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View strings and translations of a document for target language
#
# GET /projects/{projectId}/documents/{documentId}/translations/{language}
# operationId: getDocumentTranslationsForLanguage
export def "projects-documents-translations get" [
  projectId: int
  documentId: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/documents/($documentId)/translations/($language)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View glossaries
#
# GET /projects/{projectId}/glossaries
# operationId: getGlossaries
export def "projects-glossaries list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<glossaries: table<id: int, links: record, name: string, uploaded_at: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/glossaries")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a glossary file
#
# POST /projects/{projectId}/glossaries
# operationId: createGlossary
export def "projects-glossaries createGlossary" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/glossaries")
  let body = {glossaries: $glossaries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a glossary
#
# DELETE /projects/{projectId}/glossaries/{glossaryId}
# operationId: deleteGlossary
export def "projects-glossaries delete" [
  projectId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/glossaries/($glossaryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}
# operationId: getGlossary
export def "projects-glossaries get" [
  projectId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/glossaries/($glossaryId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a glossary
#
# PUT /projects/{projectId}/glossaries/{glossaryId}
# operationId: updateGlossary
export def "projects-glossaries updateGlossary" [
  projectId: int
  glossaryId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  glossaries: string # You can only add one glossary, even though the name suggests multiple glossaries. This may be updated in the future to support multiple glossaries. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/glossaries/($glossaryId)")
  let body = {glossaries: $glossaries} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a glossary
#
# GET /projects/{projectId}/glossaries/{glossaryId}/download
# operationId: downloadGlossary
export def "projects-glossaries-download downloadGlossary" [
  projectId: int
  glossaryId: int
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
  let full_url = (build-url $base $"/projects/($projectId)/glossaries/($glossaryId)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View project strings and translations
#
# GET /projects/{projectId}/strings
# operationId: getProjectStrings
export def "projects-strings list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download project translation memory
#
# POST /projects/{projectId}/strings/package
# operationId: packageProjectTranslationMemory
export def "projects-strings-package packageProjectTranslationMemory" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/strings/package" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check translation memory packaging status
#
# GET /projects/{projectId}/strings/package/status
# operationId: packageProjectTranslationMemoryStatus
export def "projects-strings-package-status packageProjectTranslationMemoryStatus" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/strings/package/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download language-specific project translation memory
#
# POST /projects/{projectId}/strings/{languageCode}/package
# operationId: packageProjectTranslationMemoryForLanguage
export def "projects-strings-package packageProjectTranslationMemoryForLanguage" [
  projectId: int
  languageCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --format: string # Translation Memory file format (default: tmx)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/strings/($languageCode)/package" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check language-specific translation memory packaging status
#
# GET /projects/{projectId}/strings/{languageCode}/package/status
# operationId: packageProjectTranslationMemoryForLanguageStatus
export def "projects-strings-package-status packageProjectTranslationMemoryForLanguageStatus" [
  projectId: int
  languageCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/strings/($languageCode)/package/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View strings and translations for target language
#
# GET /projects/{projectId}/strings/{language}
# operationId: getProjectStringsForLanguage
export def "projects-strings get" [
  projectId: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/strings/($language)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View style guides
#
# GET /projects/{projectId}/styleguides
# operationId: getStyleGuides
export def "projects-styleguides list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/styleguides" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload a new style guide
#
# POST /projects/{projectId}/styleguides
# operationId: createStyleGuide
export def "projects-styleguides createStyleGuide" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, styleguides: table<id: int, links: record, name: string, uploaded_at: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/styleguides")
  let body = {styleguides: $styleguides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a style guide
#
# DELETE /projects/{projectId}/styleguides/{styleGuideId}
# operationId: deleteStyleGuide
export def "projects-styleguides delete" [
  projectId: int
  styleGuideId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/styleguides/($styleGuideId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}
# operationId: getStyleGuide
export def "projects-styleguides get" [
  projectId: int
  styleGuideId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Attach further information. Possible values 'preview' to fetch temporary preview URLs. This is NOT recommended to be used with list calls. Only use with[]=preview for single document/style guide calls.
]: nothing -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base $"/projects/($projectId)/styleguides/($styleGuideId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a style guide
#
# PUT /projects/{projectId}/styleguides/{styleGuideId}
# operationId: updateStyleGuide
export def "projects-styleguides updateStyleGuide" [
  projectId: int
  styleGuideId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguides: string # You can only add one style guide, even though the name suggests multiple style guides. This may be updated in the future to support multiple style guides. (format: binary)
]: any -> record<id: int, links: record<self: record<href: string>, admins: record, download: record<href: string>, editors: record, preview_box: record<href: string>, preview_pdf: record<href: string>, preview_pdf_viewer: record<href: string>, progress: record<href: string>, project: record<href: string>, strings: record<href: string>, thumbnail: record<href: string>>, name: string, uploaded_at: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/styleguides/($styleGuideId)")
  let body = {styleguides: $styleguides} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download a style guide
#
# GET /projects/{projectId}/styleguides/{styleGuideId}/download
# operationId: downloadStyleGuide
export def "projects-styleguides-download downloadStyleGuide" [
  projectId: int
  styleGuideId: int
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
  let full_url = (build-url $base $"/projects/($projectId)/styleguides/($styleGuideId)/download")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecated. Use /projects/{projectId}/strings instead.
#
# GET /projects/{projectId}/translations
# DEPRECATED
# operationId: getProjectTranslations
@deprecated
export def "projects-translations list" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/translations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deprecated. use /projects/{projectId}/strings/{language} instead.
#
# GET /projects/{projectId}/translations/{language}
# DEPRECATED
# operationId: getProjectTranslationsForLanguage
@deprecated
export def "projects-translations get" [
  projectId: int
  language: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, translations: table<content: string, file_id: int, id: string, translations: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/translations/($language)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of vendors.
#
# GET /projects/{projectId}/vendors
# operationId: getProjectVendors
export def "projects-vendors get" [
  projectId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/projects/($projectId)/vendors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns available options for selected timeframe.
#
# POST /reports/filter
# operationId: getFilterContents
export def "reports-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
]: any -> record<budget_codes: list<string>, categories: list<string>, clients: table<id: int, name: string>, documents: table<id: int, name: string>, projects: table<id: int, name: string>, severities: list<string>, source_languages: list<string>, subjects: list<string>, target_languages: list<string>, vendors: table<id: int, name: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/filter")
  let body = {date_from: $date_from, date_to: $date_to} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Language pairs report
#
# POST /reports/language-pairs
# operationId: getLanguagePairsReport
export def "reports-language-pairs post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list # List of source language codes.
  --target-languages: list # List of target language codes.
  --users: list # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<language_pair: record, spending: float, word_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/language-pairs")
  let body = {budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Projects report
#
# POST /reports/projects
# operationId: getProjectsReport
export def "reports-projects post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list # List of source language codes.
  --target-languages: list # List of target language codes.
  --users: list # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/projects")
  let body = {budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate a QA report for given filter
#
# POST /reports/qa
# operationId: generateQAReport
export def "reports-qa generateQAReport" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-codes: list
  --categories: list
  --clients: list
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --documents: list
  --projects: list
  --severities: list
  --source-languages: list
  --subjects: list
  --target-languages: list
  --vendors: list
]: any -> record<report: table<category: string, comment: string, docId: string, editorLink: string, end: int, inSource: bool, isCurrent: bool, module: string, projectId: record, severity: string, source: string, sourceLanguage: record, start: int, state: string, targetLanguage: record, translation: string, uniqueKey: string, vendor: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/qa")
  let body = {budget_codes: $budget_codes, categories: $categories, clients: $clients, date_from: $date_from, date_to: $date_to, documents: $documents, projects: $projects, severities: $severities, source_languages: $source_languages, subjects: $subjects, target_languages: $target_languages, vendors: $vendors} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Company users report
#
# POST /reports/users
# operationId: getUsersReport
export def "reports-users post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list # List of source language codes.
  --target-languages: list # List of target language codes.
  --users: list # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, report: table<currency: string, spending: float, user: record, word_count: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/reports/users")
  let body = {budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends email confirmation email for current user
#
# POST /resend-email-confirmation
# operationId: sendEmailConfirmation
export def "resend-email-confirmation sendEmailConfirmation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/resend-email-confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your vendor responsiveness
#
# GET /responsivity
# operationId: getResponsivity
export def "responsivity list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Time period to calculate your responsiveness (default: monthly)
]: nothing -> record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/responsivity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Search everything in your account
#
# GET /search
# operationId: searchEverywhere
export def "search searchEverywhere" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-query: string # Search query term
  --include: list # Search in these entities. Current oprions are projects, documents, strings. Can be multiple. When not provided, we'll search through all entities.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, result: record<documents: list<record>, projects: list<record>, strings: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "query" $qp_query "scalar") (serialize-qp "include[]" $include "multi") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reindex for search all of the client source and translation documents.
#
# POST /search/documents/reindex
# operationId: reindexDocuments
export def "search-documents-reindex reindexDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/search/documents/reindex")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check reindex status of the client source and translation documents.
#
# GET /search/documents/reindex/status
# operationId: checkDocumentsReindex
export def "search-documents-reindex-status checkDocumentsReindex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/search/documents/reindex/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your account statistics
#
# GET /stats
# operationId: getStats
export def "stats list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the total commissions stats.
#
# GET /stats/commissions
# operationId: getCommissionStats
export def "stats-commissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/commissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the total commissions stats by report filter.
#
# POST /stats/commissions
# operationId: getCommissionStatsByFilter
export def "stats-commissions post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --budget-code: string # budget code filter. valid for corporate accounts only.
  --date-from: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --date-to: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --source-languages: list # List of source language codes.
  --target-languages: list # List of target language codes.
  --users: list # List of corporate user IDs. Valid for corporate accounts only.
]: any -> record<balance: record<amount: float, currency: string>, paid: record<amount: float, currency: string>, quote_total: record<amount: float, currency: string>, total: record<amount: float, currency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/commissions")
  let body = {budget_code: $budget_code, date_from: $date_from, date_to: $date_to, source_languages: $source_languages, target_languages: $target_languages, users: $users} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View your popular language pairs
#
# GET /stats/popular-pairs
# operationId: getPopularPairs
export def "stats-popular-pairs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pairs: table<source_language: string, target_language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/popular-pairs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your project statistics
#
# GET /stats/projects
# operationId: getProjectStats
export def "stats-projects list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your translation statistics
#
# GET /stats/strings
# operationId: getStringStats
export def "stats-strings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<language_counts: table<project_string_count: int, source_language: string, tm_string_count: int>, total_project_strings_count: int, total_tm_strings_count: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/stats/strings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View account strings (translation memory)
#
# GET /strings
# operationId: getStrings
export def "strings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --source-language: string # Source Language Code
  --page: int # Requested page (format: int64, default: 0)
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, strings: table<content: string, language: string, last_changed: string, translations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "source_language" $source_language "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/strings" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Translate Strings with MT
#
# POST /strings
# DEPRECATED
# operationId: postStrings
@deprecated
export def "strings post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contents: list
  --source-language: string
  --target-languages: list
]: any -> record<cost: record<amount: float, currency: string>, strings: table<content: string, language: string, last_changed: string, translations: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/strings")
  let body = {contents: $contents, source_language: $source_language, target_languages: $target_languages} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update string translation
#
# PUT /strings
# operationId: updateTranslationMemoryUnit
export def "strings updateTranslationMemoryUnit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sourceLanguage: string
  --sourceText: string
  --targetLanguage: string
  --targetText: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/strings")
  let body = {sourceLanguage: $sourceLanguage, sourceText: $sourceText, targetLanguage: $targetLanguage, targetText: $targetText} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Download account translation memory
#
# POST /strings/{languageCode}/package
# operationId: packageUserTranslationMemory
export def "strings-package packageUserTranslationMemory" [
  languageCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer-1 # Response content type
  --async: int # If you want to package and download the translation memory synchronously, mark this parameter as '0'. It will package the translation memory and then return the packaged file in the response, identical to async/download call after an asynchronous /package call. (format: int64, default: 0)
  --email: int # If you don't need us to email the TMX, set this to '0'. Default is 1. (format: int64, default: 1)
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async" $async "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/strings/($languageCode)/package" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check account translation memory packaging status
#
# GET /strings/{languageCode}/package/status
# operationId: packageUserTranslationMemoryForLanguageStatus
export def "strings-package-status packageUserTranslationMemoryForLanguageStatus" [
  languageCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --async-request-key: string # Async operation key
]: nothing -> record<duration: int, key: string, message: record, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "async_request_key" $async_request_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/strings/($languageCode)/package/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download account style guide
#
# GET /styleguide
# operationId: downloadGlobalStyleGuide
export def "styleguide downloadGlobalStyleGuide" [
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
  let full_url = (build-url $base "/styleguide")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or update the account style guide
#
# POST /styleguide
# operationId: updateGlobalStyleGuide
export def "styleguide updateGlobalStyleGuide" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  styleguide: string # Style guide file. Currently supported formats: .pdf, .docx, .txt (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/styleguide")
  let body = {styleguide: $styleguide} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get survey questions in given scope and type
#
# GET /surveys/{scope}/{type}
# operationId: getQuestions
export def "surveys get" [
  scope: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attach-answers-for-project: int # Project ID (format: int64)
]: nothing -> table<answers: list<record>, question: record<enabled: bool, format: string, id: int, question: string, text: string>, question_answers: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "attach_answers_for_project" $attach_answers_for_project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/surveys/($scope)/($type)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post survey answers for scope and type
#
# POST /surveys/{scope}/{type}
# operationId: submitAnswers
# --answers item shape: {answer?: string, project_id?: int, question_answer_id?: int, question_id?: int, user_id?: int}
export def "surveys submitAnswers" [
  scope: string
  type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --answers: list # item shape: {answer?: string, project_id?: int, question_answer_id?: int, question_id?: int, user_id?: int}
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/surveys/($scope)/($type)")
  let body = {answers: $answers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# OpenAPI YAML representation of our API
#
# GET /swagger
# operationId: getSwaggerYaml
export def "swagger get" [
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
  let full_url = (build-url $base "/swagger")
  let accept_val = "text/yaml"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve an access token
#
# POST /token
# operationId: getAccessToken
export def "token post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  grant_type: string # OAuth2 grant type. Supports 'client_credentials', 'password', 'refresh_token' or 'user_id'.
  --password: string # MW Account password (to be used in password grant type)
  --refresh-token: string # Refresh token value for refresh token flow.
  scope: string # Authorization scope. Use 'privileged' for private endpoints.
  --user-id: int # Value for user_id grant type flow. (format: int64)
  --username: string # MW Account email (to be used in password grant type)
]: any -> record<access_token: string, expires_in: int, refresh_token: string, scope: string, token_type: string, user_id: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/token")
  let body = {grant_type: $grant_type, password: $password, refresh_token: $refresh_token, scope: $scope, user_id: $user_id, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Defreeze your account
#
# POST /unfreeze-account
# operationId: unfreezeAccount
export def "unfreeze-account unfreezeAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unfreeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# View your user groups
#
# GET /user-groups
# operationId: getUserGroups
export def "user-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of platform users
#
# GET /users
# operationId: getUsers
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --user-type: string@user-type-completer # default: all
  --search: string
  --email: string
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "user_type" $user_type "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "email" $email "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new user
#
# POST /users
# operationId: createUser
# --client shape: {corporate?: record, nps?: float, subjects?: record}
# --language_pairs item shape: {source_language?: string, target_language?: string}
# --mailing shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string}
# --social_media shape: {facebook_url?: string, linkedIn_url?: string, twitter_url?: string}
# --user_groups item shape: {corporate_id?: int, id?: int, name?: string, permissions?: list}
# --vendor shape: {can_work_manual_files?: bool, email_open_rate?: float, is_frozen?: bool, is_proofreader?: bool, language_pairs?: list, native_language?: string, pam_tqs?: float, paypal_email?: string, profile_survey?: record, require_1099?: bool, tags?: list, tms_user_name?: string, vendor_type?: string}
@deprecated --flag can-work-manual-files
@deprecated --flag city
@deprecated --flag country
@deprecated --flag is-proofreader
@deprecated --flag language-pairs
@deprecated --flag native-language
@deprecated --flag nps
@deprecated --flag state
@deprecated --flag street
@deprecated --flag tms-user-name
@deprecated --flag zip-code
export def "users createUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --notify: oneof<nothing, bool> # Send a welcome email to the user (default: 1)
  --billing: any
  --birthday: string # format: date
  --can-work-manual-files: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --city: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --client: record # shape: {corporate?: record, nps?: float, subjects?: record}
  --corporate-id: int # format: int64
  --country: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --created-at: int # Unix epoch time (format: int64)
  --do-not-contact: oneof<nothing, bool>
  --email: string
  --first-name: string
  --has-pwd: oneof<nothing, bool>
  --id: int # format: int64
  --is-client: oneof<nothing, bool>
  --is-developer: oneof<nothing, bool>
  --is-proofreader: oneof<nothing, bool> # \@deprecated. use `vendor` key (DEPRECATED)
  --is-prospect: oneof<nothing, bool>
  --is-sales-person: oneof<nothing, bool>
  --is-vendor: oneof<nothing, bool>
  --language-pairs: list # \@deprecated. use `vendor` key (DEPRECATED) — item shape: {source_language?: string, target_language?: string}
  --last-name: string
  --last-seen-online-at: int # Unix epoch time (format: int64)
  --links: any
  --locale: string # User Locale
  --mailing: record # shape: {city?: string, country?: string, phone?: string, state?: string, street?: string, zip?: string}
  --name: string
  --native-language: string # \@deprecated. Native language of user (DEPRECATED)
  --nps: float # \@deprecated. use /stats endpoint for the current nps value. (DEPRECATED, format: float)
  --phone-number: string
  --profile-picture-path: string
  --social-media: record # shape: {facebook_url?: string, linkedIn_url?: string, twitter_url?: string}
  --state: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --status: string
  --street: string # \@deprecated. use mailing or billing key. (DEPRECATED)
  --timezone: string
  --tms-user-name: string # \@deprecated. use `vendor` key (DEPRECATED)
  --user-groups: list # item shape: {corporate_id?: int, id?: int, name?: string, permissions?: list}
  --vendor: record # shape: {can_work_manual_files?: bool, email_open_rate?: float, is_frozen?: bool, is_proofreader?: bool, language_pairs?: list, native_language?: string, pam_tqs?: float, paypal_email?: string, profile_survey?: record, require_1099?: bool, tags?: list, tms_user_name?: string, vendor_type?: string}
  --zip-code: string # \@deprecated. use mailing or billing key. new key name is "zip". (DEPRECATED)
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "notify" $notify "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users" $qp)
  let body = {billing: $billing, birthday: $birthday, can_work_manual_files: $can_work_manual_files, city: $city, client: $client, corporate_id: $corporate_id, country: $country, created_at: $created_at, do_not_contact: $do_not_contact, email: $email, first_name: $first_name, has_pwd: $has_pwd, id: $id, is_client: $is_client, is_developer: $is_developer, is_proofreader: $is_proofreader, is_prospect: $is_prospect, is_sales_person: $is_sales_person, is_vendor: $is_vendor, language_pairs: $language_pairs, last_name: $last_name, last_seen_online_at: $last_seen_online_at, links: $links, locale: $locale, mailing: $mailing, name: $name, native_language: $native_language, nps: $nps, phone_number: $phone_number, profile_picture_path: $profile_picture_path, social_media: $social_media, state: $state, status: $status, street: $street, timezone: $timezone, tms_user_name: $tms_user_name, user_groups: $user_groups, vendor: $vendor, zip_code: $zip_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of vendors available for the criteria given
#
# POST /users/available-vendors
# operationId: getAvailableVendors
export def "users-available-vendors post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --with: list # Include detailed information. Possible values 'user'. Requesting user info enrichment takes much longer.
  --corporateId: float # Corporate account ID to filter for vendor authorization
  --manualWorkPermission: oneof<nothing, bool> # Filter vendors for manual work permission (default: 0)
  --sourceLanguage: string # Source language code
  --targetLanguages: list # List of target language codes.
  --types: list # List of vendor types
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "with[]" $with "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/users/available-vendors" $qp)
  let body = {corporateId: $corporateId, manualWorkPermission: $manualWorkPermission, sourceLanguage: $sourceLanguage, targetLanguages: $targetLanguages, types: $types} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Filter vendors based on provided parameters
#
# POST /users/filter
# operationId: getFilteredVendors
export def "users-filter post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page: int # The page number
  --per-page: int # The number of items per page
  --order-by: string # The field to order the results by
  --order: string # The order to sort the results by (ascending or descending)
  --clients: list
  --communication-channel: list
  --corporate-ids-for-auth: list
  --corporates: list
  --country: list
  --created-at: string
  --current-services: list
  --daily-proofreading-capacity: int
  --daily-translation-capacity: int
  --destination-languages: list
  --dtp-software: list
  --email-address: string
  --experience: list
  --first-name: string
  --id: list
  --is-certified-translator: oneof<nothing, bool>
  --is-sworn-translator: oneof<nothing, bool>
  --language-pairs: list
  --last-name: string
  --last-online: string
  --last-worked: string
  --memoq: int
  --memsource: int
  --min-tqs: float
  --omegat: int
  --project-count: int
  --proofreader-experience: int
  --provides-creative-writing-service: oneof<nothing, bool>
  --provides-postedit-service: oneof<nothing, bool>
  --quote-file-subjects: list
  --reference: string
  --sdl-trados: int
  --search: string
  --skype-id: string
  --smartcat: int
  --smartling: int
  --source-languages: list
  --specialization: list
  --status: list
  --subtitle-edit: int
  --subtitle-workshop: int
  --translator-association: string
  --transsuite-2000: int
  --user-working-timezone: list
  --vendor-profile-lsp: string
  --vendor-tags: list
  --vendor-type: list
  --vendor-working-timezone: list
  --word-count: int
  --wordbee: int
  --wordfast: int
  --work-type: string
  --work-with: string
  --working-as: list
  --xbench: int
  --xtm: int
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, users: table<billing: record, birthday: string, can_work_manual_files: bool, city: string, client: record, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: list, last_name: string, last_seen_online_at: int, links: record, locale: string, mailing: record, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: list, vendor: record, zip_code: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order" $order "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/users/filter" $qp)
  let body = {clients: $clients, communication_channel: $communication_channel, corporate_ids_for_auth: $corporate_ids_for_auth, corporates: $corporates, country: $country, created_at: $created_at, current_services: $current_services, daily_proofreading_capacity: $daily_proofreading_capacity, daily_translation_capacity: $daily_translation_capacity, destination_languages: $destination_languages, dtp_software: $dtp_software, email_address: $email_address, experience: $experience, first_name: $first_name, id: $id, is_certified_translator: $is_certified_translator, is_sworn_translator: $is_sworn_translator, language_pairs: $language_pairs, last_name: $last_name, last_online: $last_online, last_worked: $last_worked, memoq: $memoq, memsource: $memsource, min_tqs: $min_tqs, omegat: $omegat, project_count: $project_count, proofreader_experience: $proofreader_experience, provides_creative_writing_service: $provides_creative_writing_service, provides_postedit_service: $provides_postedit_service, quote_file_subjects: $quote_file_subjects, reference: $reference, sdl_trados: $sdl_trados, search: $search, skype_id: $skype_id, smartcat: $smartcat, smartling: $smartling, source_languages: $source_languages, specialization: $specialization, status: $status, subtitle_edit: $subtitle_edit, subtitle_workshop: $subtitle_workshop, translator_association: $translator_association, transsuite_2000: $transsuite_2000, user_working_timezone: $user_working_timezone, vendor_profile_lsp: $vendor_profile_lsp, vendor_tags: $vendor_tags, vendor_type: $vendor_type, vendor_working_timezone: $vendor_working_timezone, word_count: $word_count, wordbee: $wordbee, wordfast: $wordfast, work_type: $work_type, work_with: $work_with, working_as: $working_as, xbench: $xbench, xtm: $xtm} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sends password reset email to the user's registered email address
#
# POST /users/send-password-reminder
# operationId: sendPasswordReminder
export def "users-send-password-reminder sendPasswordReminder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --email: string
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/send-password-reminder")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns all vendor tags for vendors filter
#
# GET /users/tags
# operationId: getAllVendorTags
export def "users-tags get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<color: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/users/tags")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user information, including client or vendor specific info.
#
# GET /{userId}
# operationId: getUser
export def "user get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}
#
# operationId: updateUser
# --notifications shape: {phone_number?: string, sms_enabled?: bool}
export def "user updateUser" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --city: string
  --country: string
  --phone: string
  --state: string
  --street: string
  --zip: string
  --birthday: string # format: date
  --email: string # Optional. User e-mail.
  --first-name: string # Optional. User first name.
  --id: int # Optional. ID of the user being updated. (format: int64)
  --last-name: string # Optional. User last name.
  --notifications: record # Notification settings — shape: {phone_number?: string, sms_enabled?: bool}
  --notify: oneof<nothing, bool> # Notify new user account creation with login information and MotaWord introduction.
  --paypal-email: string # Optional. Vendor paypal e-mail
  --require-1099: oneof<nothing, bool> # Optional. Whether this vendor requires 1099 form in US for their earnings.
  --user-groups: list # A list of user group IDs
]: any -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, birthday: string, can_work_manual_files: bool, city: string, client: record<corporate: record<email: string, id: int, logo: string, name: string, phone_number: string>, nps: float, subjects: record>, corporate_id: int, country: string, created_at: int, do_not_contact: bool, email: string, first_name: string, has_pwd: bool, id: int, is_client: bool, is_developer: bool, is_proofreader: bool, is_prospect: bool, is_sales_person: bool, is_vendor: bool, language_pairs: table<source_language: string, target_language: string>, last_name: string, last_seen_online_at: int, links: record<self: record<href: string>, login_as: record<href: string>, projects: record<href: string>, responsivity: record<href: string>, stats: record<href: string>>, locale: string, mailing: record<city: string, country: string, phone: string, state: string, street: string, zip: string>, name: string, native_language: string, nps: float, phone_number: string, profile_picture_path: string, social_media: record<facebook_url: string, linkedIn_url: string, twitter_url: string>, state: string, status: string, street: string, timezone: string, tms_user_name: string, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>, vendor: record<can_work_manual_files: bool, email_open_rate: float, is_frozen: bool, is_proofreader: bool, language_pairs: list<record>, native_language: string, pam_tqs: float, paypal_email: string, profile_survey: record<current_services: string, daily_proofreading_capacity: string, daily_translation_capacity: string, dtp_software: string, experience: string, is_certified_translator: string, is_sworn_translator: string, memoq: string, memsource: string, omegat: string, proofreader_experience: string, provides_creative_writing_service: string, provides_postedit_service: string, reference: string, sdl_trados: string, skype_id: string, smartcat: string, smartling: string, software: string, specialization: string, subtitle_edit: string, subtitle_workshop: string, translator_association: string, transsuite_2000: string, vendor_profile_lsp: string, wordbee: string, wordfast: string, work_type: string, work_with: string, working_as: string, working_timezone: string, xbench: string, xtm: string>, require_1099: bool, tags: list<string>, tms_user_name: string, vendor_type: string>, zip_code: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)")
  let body = {city: $city, country: $country, phone: $phone, state: $state, street: $street, zip: $zip, birthday: $birthday, email: $email, first_name: $first_name, id: $id, last_name: $last_name, notifications: $notifications, notify: $notify, paypal_email: $paypal_email, require_1099: $require_1099, user_groups: $user_groups} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /{userId}/approve
#
# operationId: approveVendorApplication
export def "approve approveVendorApplication" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/approve")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete requester account
#
# DELETE /{userId}/delete-account
# operationId: deleteUserAccount
export def "delete-account delete-by-userId" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/delete-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of your documents
#
# GET /{userId}/documents
# operationId: getUserDocuments
export def "documents get-by-userId" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recent: oneof<nothing, bool> # When true, this will return the most 4 recent active documents. (default: 0)
  --search: string
  --type-filter: string@type-filter-completer # default: ALL
  --language-code: string # searches in source language of documents, in source and target languages of document's quote
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
  --order-by: string@order-by-completer # default: updated_at
  --order-type: string@order-type-completer
]: nothing -> record<documents: table<file_type: string, has_custom_package: bool, id: int, links: record, manual_files: list, name: string, project_id: int, review_in_manual_editor: bool, scheme: record, search_score: float, source_language: string, subject: string, target_languages: list, uploaded_at: int, word_count: int>, meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "recent" $recent "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "type_filter" $type_filter "scalar") (serialize-qp "language_code" $language_code "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar") (serialize-qp "order_by" $order_by "scalar") (serialize-qp "order_type" $order_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($userId)/documents" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/downgrade-proofreader
#
# operationId: downgradeUserProofreader
export def "downgrade-proofreader downgradeUserProofreader" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/downgrade-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns your vendor earnings. Includes real-time earnings from ongoing projects, and fixed earnings from completed projects. Also includes total earnings and string edits.
#
# GET /{userId}/earnings
# operationId: getUserEarnings
export def "earnings get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<completed: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, ongoing: table<amount: float, currency: string, due_date: string, status: string, words: int, words_approved: int, words_translated: int, is_above_average: bool, score: float, strings_edited: int, strings_translated: int, project_id: int>, total: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/earnings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Freeze requester account for project notifications
#
# POST /{userId}/freeze-account
# operationId: freezeUserAccount
export def "freeze-account freezeUserAccount" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/freeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/make-proofreader
#
# operationId: makeUserProofreader
export def "make-proofreader makeUserProofreader" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/make-proofreader")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/notifications/subscribe
#
# operationId: subscribeUserNotification
export def "notifications-subscribe subscribeUserNotification" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/notifications/subscribe")
  let body = {device: $device, endpoint: $endpoint, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# POST /{userId}/notifications/unsubscribe
#
# operationId: unsubscribeUserNotification
export def "notifications-unsubscribe unsubscribeUserNotification" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --device: string@device-completer
  --endpoint: string # OneSignal calls this "player ID".
  --type: string@type-completer-1 # default: OneSignal
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/notifications/unsubscribe")
  let body = {device: $device, endpoint: $endpoint, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View user's payment and billing info
#
# GET /{userId}/payment
# operationId: getUserPaymentInfo
export def "payment get-by-userId" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, cards: table<bin: string, id: int, is_default: bool, payment_code: string>, corporate: record<allow_api_invoicing: bool, allow_payment_code: bool, auto_charge: bool, billing: record<city: string, country: string, phone: string, state: string, street: string, zip: string, name: string>, card: record<bin: string, id: int, is_default: bool, payment_code: string>, contact_email_address: string, payment_code: string>, shared_card: record<bin: string, id: int, is_default: bool, payment_code: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/payment")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update user payment info
#
# POST /{userId}/payment
# operationId: updateUserPaymentInfo
# --card shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
# --cards item shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
# --corporate shape: {allow_api_invoicing?: bool, allow_payment_code?: bool, auto_charge?: bool, billing?: any, card?: record, contact_email_address?: string, payment_code?: string}
# --shared_card shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
export def "payment updateUserPaymentInfo" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --billing: any
  --card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --cards: list # item shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
  --corporate: record # shape: {allow_api_invoicing?: bool, allow_payment_code?: bool, auto_charge?: bool, billing?: any, card?: record, contact_email_address?: string, payment_code?: string}
  --shared-card: record # shape: {bin?: string, id?: int, is_default?: bool, payment_code?: string}
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/payment")
  let body = {billing: $billing, card: $card, cards: $cards, corporate: $corporate, shared_card: $shared_card} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns a list of permissions that this user is authorized for.
#
# GET /{userId}/permissions
# operationId: getUserPermissions
export def "permissions get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, permissions: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/permissions")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/profile-picture
#
# operationId: uploadUserProfilePicture
export def "profile-picture uploadUserProfilePicture" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture: string # Profile picture file contents. Accepted extensions are png, jpg. (format: binary)
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/profile-picture")
  let body = {profile_picture: $profile_picture} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of user/vendor projects
#
# GET /{userId}/projects/vendor
# operationId: getVendorProjectsByUserId
export def "projects-vendor get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --joined: oneof<nothing, bool> # Return only projects that this user has already joined
  --completed: oneof<nothing, bool> # Return only projects that have been completed. When `true`, this makes `joined` true as well.
  --page: int # format: int64, default: 1
  --per-page: int # format: int64, default: 10
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, projects: table<average_scores: record, budget_code: string, callback_url: string, can_pam_manage: bool, client: record, cm_id: int, completed_on: string, continuous_project_type: string, created_at: int, custom: record, delivery_at: int, errors: list, id: int, is_api_project: bool, is_certified: bool, is_continuous: bool, is_manual: bool, links: record, pairs: list, pivoted_projects: list, price: record, price_without_discount: record, role: string, should_send_client_survey: bool, source: string, source_language: string, status: string, subjects: list, target_languages: list, tms_name: string, valid_until: int, vendor_word_count: int, word_count: int, word_count_analysis: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "joined" $joined "scalar") (serialize-qp "completed" $completed "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "per_page" $per_page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($userId)/projects/vendor" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/reject
#
# operationId: rejectVendorApplication
export def "reject rejectVendorApplication" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/reject")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sends email confirmation email for a user
#
# POST /{userId}/resend-email-confirmation
# operationId: sendUserEmailConfirmation
export def "resend-email-confirmation sendUserEmailConfirmation" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/resend-email-confirmation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a user's vendor responsivity stats
#
# GET /{userId}/responsivity
# operationId: getUserResponsivity
export def "responsivity get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --period: string@period-completer # Period for calcualtion. (default: monthly)
]: nothing -> record<links: record<self: record<href: string>>, responsivity: table<invited: int, month: string, notEntered: int, onlyEntered: int, score: float, week: string, worked: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "period" $period "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/($userId)/responsivity" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a user's client and vendor statistics. This used to be called "summary" (\@deprecated).
#
# GET /{userId}/stats
# operationId: getUserStats
export def "stats get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<client: record<document_count: int, nps: float, started_project_count: int, total_discounted: record<amount: float, currency: string>, total_project_count: int, total_spending: float, translator_count: int>, vendor: record<earnings: record<total: float>, projects: record<invited: int, total: int, worked: int>, words: record<approved: int, translated: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/stats")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the language pairs that the user has ordered most.
#
# GET /{userId}/stats/popular-pairs
# operationId: getUserPopularPairs
export def "stats-popular-pairs get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<pairs: table<source_language: string, target_language: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/stats/popular-pairs")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a user's project statistics.
#
# GET /{userId}/stats/projects
# operationId: getUserProjectStats
export def "stats-projects get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stats: table<languages: list, month: string, number_of_projects: int, total_spending: float, week: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/stats/projects")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/suspend
#
# operationId: suspendUser
export def "suspend suspendUser" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reason: string # Suspension reason for vendor
]: any -> record<status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/suspend")
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unfreeze requester account for project notifications
#
# POST /{userId}/unfreeze-account
# operationId: unfreezeUserAccount
export def "unfreeze-account unfreezeUserAccount" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/unfreeze-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a list of user groups that this user belongs to.
#
# GET /{userId}/user-groups
# operationId: getThisUserGroups
export def "user-groups get" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/user-groups")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# POST /{userId}/user-groups
#
# operationId: updateUserGroup
export def "user-groups updateUserGroup" [
  userId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --allow-hash-in-url: oneof<nothing, bool> # When true, hash params are included in filenames. When false, params are ignored.
  --allow-query-in-url: oneof<nothing, bool> # When true, query params are included in filenames. When false, params are ignored.
  --auto-detect-source-language: oneof<nothing, bool> # When true, we will ignore the source language of your project and try to automatically detect the source language of the given content. This is especially useful in environments with unpredictable source contents, such as a chat environment.
  --created-at: string # the date-time notation as defined by RFC 3339, section 5.6, for example, 2017-07-21T17:32:28Z (format: date-time)
  --elements: string # Continuous project exclusive elements and rules
  --follow-user: oneof<nothing, bool> # Specify whether we should follow the user around in your website and automatically translate pages.
  --force-cache-refresh-interval: oneof<nothing, bool> # Determines whether to force-refresh local browser cache of your translations in certain period of times, no matter if there is a new activity in the project.
  --id: int # format: int64
  --language-mappings: string # Continuous project language mappings
  --live: oneof<nothing, bool> # Whether ActiveJS should be considered live in an embedded site. Use `false` if you are still testing Active. Go to your Active dashboard and follow links to your website to actually test Active.
  --modify-links: oneof<nothing, bool> # We can automatically localize the same-domain URLs in your page. The way we localize the URL depends on urlMode configuration. We can either add/update the locale query parameter, or add/update the path of the URL.
  --name: string
  --optimize-per-page: oneof<nothing, bool> # When true, Active ecosystem will optimize the script and data flows per page, rather than per project. This decreases the bandwidth usage per script, but makes translation publishing more complex and script serving per-page.
  --pages: string # Continuous project page rules
  --path-regex: string # Custom regex for path-type URL mode.
  --position: string # Options are "bottom-left", "bottom-right", "in-place"
  --query-name: string # Query parameter name to be used with query-type URL mode. Default is 'locale'. (default: locale)
  --reboot-on-url-change: oneof<nothing, bool> # When true, Active ecosystem reboots itself when url changes.
  --restricted-domains: string # JSON string for a list of domains that this widget's API interactions are limited to.
  --sections: string # Continuous project section rules
  --test-mode: oneof<nothing, bool> # Is the Active Widget in test mode? This changes a couple behaviors in the widget to make it easier for you to test and develop your Active integration.
  --theme: string # \"light\", \"dark\" OR custom JSON.
  --body-token: string # Token that you should use when you are using this widget on your website.
  --url-change-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can do this by actually redirecting the user to the new page, or by simply changing the URL in the address bar via browser's History API. When NULL, we won't apply any URL changes.
  --url-mode: string # When a user changes locale (or when we automatically detect and change it for them), we will change the URL of the page they are in. We can either change the path of the URL to prefix it with the locale code, or we can add a query parameter to the URL. We also use this mode to detect the locale for the current page when a user directly loads a page. When NULL, locale detection from URL will be disabled (even then, if the user has selected a locale manually, and followUser is enabled, we will still automatically translate the page in user's locale.
  --use-cache: oneof<nothing, bool> # Should we make use of local browser cache for your visitors? We will refresh the cache when Active JS detects new activity in your project.
  --use-dummy-translations: oneof<nothing, bool> # When enabled, we will translate your website with dummy content, rather than actually using MT/TM.
  --body-variables: string # Continuous project variable definitions
]: any -> record<meta: record<paging: record<count: int, links: record, page: int, per_page: int, total_count: int>>, user_groups: table<corporate_id: int, id: int, name: string, permissions: list>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/($userId)/user-groups")
  let body = {allow_hash_in_url: $allow_hash_in_url, allow_query_in_url: $allow_query_in_url, auto_detect_source_language: $auto_detect_source_language, created_at: $created_at, elements: $elements, follow_user: $follow_user, force_cache_refresh_interval: $force_cache_refresh_interval, id: $id, language_mappings: $language_mappings, live: $live, modify_links: $modify_links, name: $name, optimize_per_page: $optimize_per_page, pages: $pages, path_regex: $path_regex, position: $position, query_name: $query_name, reboot_on_url_change: $reboot_on_url_change, restricted_domains: $restricted_domains, sections: $sections, test_mode: $test_mode, theme: $theme, token: $body_token, url_change_mode: $url_change_mode, url_mode: $url_mode, use_cache: $use_cache, use_dummy_translations: $use_dummy_translations, variables: $body_variables} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
