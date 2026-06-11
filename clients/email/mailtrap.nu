# Auto-generated client for Email Sending v2.0.0
# Source: https://raw.githubusercontent.com/mailtrap/mailtrap-openapi/main/specs/email-sending.openapi.yml
# Auth: --token flag or $env.EMAIL_SENDING_TOKEN

const BASE_URL = "https://mailtrap.io"
const DEFAULT_AUTH = "api-token"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EMAIL_SENDING_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api-token" => { {headers: {Api-Token: $token_val}, query: ""} }
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
def base-url-completer [] { ["https://mailtrap.io"] }
def auth-scheme-completer [] { ["api-token" "bearer"] }

# Completers for enum parameters
def sending-stream-completer [] { ["bulk" "transactional"] }
def type-completer [] { ["hard bounce" "manual import" "spam complaint" "unsubscription"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "domains createDomain" } } | get name | first)
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

# Create domain
#
# POST /api/domains
# operationId: createDomain
# --domain shape: {domain_name: string}
export def "domains createDomain" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: record # shape: {domain_name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/domains")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List domains
#
# GET /api/domains
# operationId: getDomains
export def "domains list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/domains")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get domain
#
# GET /api/domains/{domain_id}
# operationId: getDomain
export def "domains get" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete domain
#
# DELETE /api/domains/{domain_id}
# operationId: deleteDomain
export def "domains delete" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update domain
#
# PATCH /api/domains/{domain_id}
# operationId: updateDomain
# --domain shape: {open_tracking_enabled?: bool, click_tracking_enabled?: bool, auto_unsubscribe_link_enabled?: bool}
export def "domains updateDomain" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  domain: record # shape: {open_tracking_enabled?: bool, click_tracking_enabled?: bool, auto_unsubscribe_link_enabled?: bool}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)")
  let body = {domain: $domain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Send setup instructions
#
# POST /api/domains/{domain_id}/send_setup_instructions
# operationId: sendDomainSetupInstructions
export def "domains-send-setup-instructions sendDomainSetupInstructions" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email address to receive setup instructions (format: email)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)/send_setup_instructions")
  let body = {email: $email} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get company info
#
# GET /api/domains/{domain_id}/company_info
# operationId: getDomainCompanyInfo
export def "domains-company-info get" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)/company_info")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create company info
#
# POST /api/domains/{domain_id}/company_info
# operationId: createDomainCompanyInfo
# --company_info shape: {name: string, address: string, city: string, country: string, phone?: string, zip_code: string, privacy_policy_url?: string, terms_of_service_url?: string, website_url: string, info_level?: "business"|"individual"}
export def "domains-company-info createDomainCompanyInfo" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  company_info: record # shape: {name: string, address: string, city: string, country: string, phone?: string, zip_code: string, privacy_policy_url?: string, terms_of_service_url?: string, website_url: string, info_level?: "business"|"individual"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)/company_info")
  let body = {company_info: $company_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update company info
#
# PATCH /api/domains/{domain_id}/company_info
# operationId: updateDomainCompanyInfo
# --company_info shape: {name?: string, address?: string, city?: string, country?: string, phone?: string, zip_code?: string, privacy_policy_url?: string, terms_of_service_url?: string, website_url?: string, info_level?: "business"|"individual"}
export def "domains-company-info updateDomainCompanyInfo" [
  domain_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  company_info: record # All fields are optional. Only the fields provided in the request will be updated. — shape: {name?: string, address?: string, city?: string, country?: string, phone?: string, zip_code?: string, privacy_policy_url?: string, terms_of_service_url?: string, website_url?: string, info_level?: "business"|"individual"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/domains/($domain_id)/company_info")
  let body = {company_info: $company_info} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List suppressions
#
# GET /api/suppressions
# operationId: getSuppressions
export def "suppressions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --email: string # Filter suppressions by exact email address (case-insensitive). (format: email, e.g. suppressed@example.com)
  --start-time: string # Filter suppressions created at or after this timestamp (ISO 8601 format). (format: date-time, e.g. 2025-01-01T00:00:00Z)
  --end-time: string # Filter suppressions created at or before this timestamp (ISO 8601 format). (format: date-time, e.g. 2025-12-31T23:59:59Z)
  --last-id: string # The suppression UUID from the last record of the previous response. Returns records after this suppression, enabling cursor-based pagination through large lists. (format: uuid, e.g. 64d71bf3-1276-417b-86e1-8e66f138acfe)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "email" $email "scalar") (serialize-qp "start_time" $start_time "scalar") (serialize-qp "end_time" $end_time "scalar") (serialize-qp "last_id" $last_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/suppressions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create suppression
#
# POST /api/suppressions
# operationId: createSuppression
export def "suppressions createSuppression" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  email: string # Email address to suppress (format: email, e.g. user@example.com)
  domain_id: int # ID of the domain to suppress this email for (e.g. 12345)
  sending_stream: string@sending-stream-completer # The sending stream to suppress this email for (e.g. transactional)
  --type: string@type-completer # Reason for the suppression. Defaults to "manual import" if omitted. (default: manual import, e.g. manual import)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/suppressions")
  let body = {email: $email, domain_id: $domain_id, sending_stream: $sending_stream, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete suppression
#
# DELETE /api/suppressions/{suppression_id}
# operationId: deleteSuppression
export def "suppressions delete" [
  suppression_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/suppressions/($suppression_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sending Stats
#
# GET /api/stats
# operationId: getAccountSendingStats
export def "stats get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for which to include the results. (format: date, e.g. 2025-01-01)
  --end-date: string # End date for which to include the results. (format: date, e.g. 2025-12-31)
  --domain-ids: list # IDs of the domains for which to include the results. If not provided, results for all domains will be included. (e.g. [3938, 3939])
  --sending-streams: list # Sending streams for which to include the results. If not provided, results for all sending streams will be included. (e.g. [transactional, bulk])
  --categories: list # Categories for which to include the results. If not provided, results for all categories will be included. (e.g. [Welcome Email, Password Reset])
  --email-service-providers: list # Email service providers for which to include the results. If not provided, results for all ESPs will be included. (e.g. [Google, Yahoo])
]: nothing -> record<delivery_count: int, delivery_rate: float, bounce_count: int, bounce_rate: float, open_count: int, open_rate: float, click_count: int, click_rate: float, spam_count: int, spam_rate: float> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domain_ids[]" $domain_ids "multi") (serialize-qp "sending_streams[]" $sending_streams "multi") (serialize-qp "categories[]" $categories "multi") (serialize-qp "email_service_providers[]" $email_service_providers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/stats" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sending Stats by Domains
#
# GET /api/stats/domains
# operationId: getAccountSendingStatsByDomains
export def "stats-domains get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for which to include the results. (format: date, e.g. 2025-01-01)
  --end-date: string # End date for which to include the results. (format: date, e.g. 2025-12-31)
  --domain-ids: list # IDs of the domains for which to include the results. If not provided, results for all domains will be included. (e.g. [3938, 3939])
  --sending-streams: list # Sending streams for which to include the results. If not provided, results for all sending streams will be included. (e.g. [transactional, bulk])
  --categories: list # Categories for which to include the results. If not provided, results for all categories will be included. (e.g. [Welcome Email, Password Reset])
  --email-service-providers: list # Email service providers for which to include the results. If not provided, results for all ESPs will be included. (e.g. [Google, Yahoo])
]: nothing -> table<domain_id: int, stats: record<delivery_count: int, delivery_rate: float, bounce_count: int, bounce_rate: float, open_count: int, open_rate: float, click_count: int, click_rate: float, spam_count: int, spam_rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domain_ids[]" $domain_ids "multi") (serialize-qp "sending_streams[]" $sending_streams "multi") (serialize-qp "categories[]" $categories "multi") (serialize-qp "email_service_providers[]" $email_service_providers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/stats/domains" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sending Stats by Categories
#
# GET /api/stats/categories
# operationId: getAccountSendingStatsByCategories
export def "stats-categories get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for which to include the results. (format: date, e.g. 2025-01-01)
  --end-date: string # End date for which to include the results. (format: date, e.g. 2025-12-31)
  --domain-ids: list # IDs of the domains for which to include the results. If not provided, results for all domains will be included. (e.g. [3938, 3939])
  --sending-streams: list # Sending streams for which to include the results. If not provided, results for all sending streams will be included. (e.g. [transactional, bulk])
  --categories: list # Categories for which to include the results. If not provided, results for all categories will be included. (e.g. [Welcome Email, Password Reset])
  --email-service-providers: list # Email service providers for which to include the results. If not provided, results for all ESPs will be included. (e.g. [Google, Yahoo])
]: nothing -> table<category: string, stats: record<delivery_count: int, delivery_rate: float, bounce_count: int, bounce_rate: float, open_count: int, open_rate: float, click_count: int, click_rate: float, spam_count: int, spam_rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domain_ids[]" $domain_ids "multi") (serialize-qp "sending_streams[]" $sending_streams "multi") (serialize-qp "categories[]" $categories "multi") (serialize-qp "email_service_providers[]" $email_service_providers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/stats/categories" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sending Stats by Email Service Providers
#
# GET /api/stats/email_service_providers
# operationId: getAccountSendingStatsByEmailServiceProviders
export def "stats-email-service-providers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for which to include the results. (format: date, e.g. 2025-01-01)
  --end-date: string # End date for which to include the results. (format: date, e.g. 2025-12-31)
  --domain-ids: list # IDs of the domains for which to include the results. If not provided, results for all domains will be included. (e.g. [3938, 3939])
  --sending-streams: list # Sending streams for which to include the results. If not provided, results for all sending streams will be included. (e.g. [transactional, bulk])
  --categories: list # Categories for which to include the results. If not provided, results for all categories will be included. (e.g. [Welcome Email, Password Reset])
  --email-service-providers: list # Email service providers for which to include the results. If not provided, results for all ESPs will be included. (e.g. [Google, Yahoo])
]: nothing -> table<email_service_provider: string, stats: record<delivery_count: int, delivery_rate: float, bounce_count: int, bounce_rate: float, open_count: int, open_rate: float, click_count: int, click_rate: float, spam_count: int, spam_rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domain_ids[]" $domain_ids "multi") (serialize-qp "sending_streams[]" $sending_streams "multi") (serialize-qp "categories[]" $categories "multi") (serialize-qp "email_service_providers[]" $email_service_providers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/stats/email_service_providers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get Sending Stats by Date
#
# GET /api/stats/date
# operationId: getAccountSendingStatsByDate
export def "stats-date get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --start-date: string # Start date for which to include the results. (format: date, e.g. 2025-01-01)
  --end-date: string # End date for which to include the results. (format: date, e.g. 2025-12-31)
  --domain-ids: list # IDs of the domains for which to include the results. If not provided, results for all domains will be included. (e.g. [3938, 3939])
  --sending-streams: list # Sending streams for which to include the results. If not provided, results for all sending streams will be included. (e.g. [transactional, bulk])
  --categories: list # Categories for which to include the results. If not provided, results for all categories will be included. (e.g. [Welcome Email, Password Reset])
  --email-service-providers: list # Email service providers for which to include the results. If not provided, results for all ESPs will be included. (e.g. [Google, Yahoo])
]: nothing -> table<date: string, stats: record<delivery_count: int, delivery_rate: float, bounce_count: int, bounce_rate: float, open_count: int, open_rate: float, click_count: int, click_rate: float, spam_count: int, spam_rate: float>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "start_date" $start_date "scalar") (serialize-qp "end_date" $end_date "scalar") (serialize-qp "domain_ids[]" $domain_ids "multi") (serialize-qp "sending_streams[]" $sending_streams "multi") (serialize-qp "categories[]" $categories "multi") (serialize-qp "email_service_providers[]" $email_service_providers "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/api/stats/date" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List email logs
#
# GET /api/email_logs
# operationId: listEmailLogs
export def "email-logs listEmailLogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search-after: string # Cursor for the next page (message_id UUID from previous response next_page_cursor). (format: uuid)
  --filters: record # Filter criteria (deep object). Pass as `filters[field][operator]` and `filters[field][value]`. When a filter accepts an array value, use bracket notation: `filters[field][value][]=item1&filters[field][value][]=item2`. Date range: use `filters[sent_after]` and `filters[sent_before]` (ISO 8601 strings). Unknown filters are ignored.
]: nothing -> record<messages: table<message_id: string, status: string, subject: string, from: string, to: string, sent_at: string, client_ip: string, category: string, custom_variables: record, sending_stream: string, domain_id: int, template_id: int, template_variables: record, opens_count: int, clicks_count: int>, total_count: int, next_page_cursor: string> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search_after" $search_after "scalar") (serialize-qp "filters" $filters "deepObject")] | flatten | str join "&"
  let full_url = (build-url $base "/api/email_logs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get an email log message by ID
#
# GET /api/email_logs/{sending_message_id}
# operationId: getEmailLogMessage
export def "email-logs get" [
  sending_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<message_id: string, status: string, subject: string, from: string, to: string, sent_at: string, client_ip: string, category: string, custom_variables: record, sending_stream: string, domain_id: int, template_id: int, template_variables: record, opens_count: int, clicks_count: int, raw_message_url: string, events: list<any>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/email_logs/($sending_message_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a webhook
#
# POST /api/webhooks
# operationId: createWebhook
# --webhook shape: {url: string, webhook_type: "email_sending"|"campaigns"|"audit_log"|"inbound_receiving", active?: bool, payload_format?: "json"|"jsonlines", sending_stream?: "transactional"|"bulk", event_types?: list, domain_id?: int, inbound_inbox_id?: int}
export def "webhooks createWebhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  webhook: record # shape: {url: string, webhook_type: "email_sending"|"campaigns"|"audit_log"|"inbound_receiving", active?: bool, payload_format?: "json"|"jsonlines", sending_stream?: "transactional"|"bulk", event_types?: list, domain_id?: int, inbound_inbox_id?: int}
]: any -> record<data: record<id: int, url: string, active: bool, webhook_type: string, payload_format: string, sending_stream: string, domain_id: int, inbound_inbox_id: int, event_types: list<string>, signing_secret: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhooks")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List webhooks
#
# GET /api/webhooks
# operationId: listWebhooks
export def "webhooks listWebhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: table<id: int, url: string, active: bool, webhook_type: string, payload_format: string, sending_stream: string, domain_id: int, inbound_inbox_id: int, event_types: list>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/webhooks")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a webhook
#
# GET /api/webhooks/{webhook_id}
# operationId: getWebhook
export def "webhooks get" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, url: string, active: bool, webhook_type: string, payload_format: string, sending_stream: string, domain_id: int, inbound_inbox_id: int, event_types: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a webhook
#
# PATCH /api/webhooks/{webhook_id}
# operationId: updateWebhook
# --webhook shape: {url?: string, active?: bool, payload_format?: "json"|"jsonlines", event_types?: list, inbound_inbox_id?: int}
export def "webhooks updateWebhook" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  webhook: record # shape: {url?: string, active?: bool, payload_format?: "json"|"jsonlines", event_types?: list, inbound_inbox_id?: int}
]: any -> record<data: record<id: int, url: string, active: bool, webhook_type: string, payload_format: string, sending_stream: string, domain_id: int, inbound_inbox_id: int, event_types: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhooks/($webhook_id)")
  let body = {webhook: $webhook} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a webhook
#
# DELETE /api/webhooks/{webhook_id}
# operationId: deleteWebhook
export def "webhooks delete" [
  webhook_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<data: record<id: int, url: string, active: bool, webhook_type: string, payload_format: string, sending_stream: string, domain_id: int, inbound_inbox_id: int, event_types: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "api-token"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhooks/($webhook_id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
