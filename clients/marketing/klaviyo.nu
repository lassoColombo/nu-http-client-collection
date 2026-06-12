# Auto-generated client for Klaviyo API v2026-04-15
# Source: https://raw.githubusercontent.com/klaviyo/openapi/main/openapi/stable.json
# Auth: --token flag or $env.KLAVIYO_API_TOKEN

const BASE_URL = "https://a.klaviyo.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o KLAVIYO_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://a.klaviyo.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def sort-completer [] { ["-created_at" "-id" "-name" "-scheduled_at" "-updated_at" "created_at" "id" "name" "scheduled_at" "updated_at"] }
def sort-completer-1 [] { ["-created" "created"] }
def sort-completer-2 [] { ["-datetime" "-timestamp" "datetime" "timestamp"] }
def sort-completer-3 [] { ["-created" "-id" "-name" "-status" "-trigger_type" "-updated" "created" "id" "name" "status" "trigger_type" "updated"] }
def sort-completer-4 [] { ["-action_type" "-created" "-id" "-status" "-updated" "action_type" "created" "id" "status" "updated"] }
def sort-completer-5 [] { ["-created" "-id" "-name" "-updated" "created" "id" "name" "updated"] }
def sort-completer-6 [] { ["-created_at" "-updated_at" "created_at" "updated_at"] }
def sort-completer-7 [] { ["-format" "-id" "-name" "-size" "-updated_at" "format" "id" "name" "size" "updated_at"] }
def sort-completer-8 [] { ["-joined_group_at" "joined_group_at"] }
def sort-completer-9 [] { ["-created" "-email" "-id" "-subscriptions.email.marketing.list_suppressions.timestamp" "-subscriptions.email.marketing.suppression.timestamp" "-updated" "created" "email" "id" "subscriptions.email.marketing.list_suppressions.timestamp" "subscriptions.email.marketing.suppression.timestamp" "updated"] }
def sort-completer-10 [] { ["-created_at" "created_at"] }
def sort-completer-11 [] { ["-created" "-rating" "-updated" "created" "rating" "updated"] }
def sort-completer-12 [] { ["-id" "-name" "id" "name"] }
def sort-completer-13 [] { ["-created" "-name" "-updated" "created" "name" "updated"] }
def group-by-completer [] { ["company_id" "product_id"] }
def timeframe-completer [] { ["all_time" "last_30_days" "last_365_days" "last_90_days"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts accounts" } } | get name | first)
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

# Get Accounts
#
# GET /api/accounts
# operationId: get_accounts
export def "accounts accounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsaccount: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[account]" $fieldsaccount "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/accounts" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account
#
# GET /api/accounts/{id}
# operationId: get_account
export def "accounts account" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsaccount: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[account]" $fieldsaccount "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/accounts/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Campaigns
#
# GET /api/campaigns
# operationId: get_campaigns
export def "campaigns campaigns" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`<br>`messages.channel`: `equals`<br>`name`: `contains`<br>`status`: `any`, `equals`<br>`archived`: `equals`<br>`created_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`scheduled_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(messages.channel,'email'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv") (serialize-qp "fields[campaign]" $fieldscampaign "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaigns" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Campaign
#
# POST /api/campaigns
# operationId: create_campaign
export def "campaigns campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign]" $fieldscampaign "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaigns" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Campaign
#
# GET /api/campaigns/{id}
# operationId: get_campaign
export def "campaigns campaign-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv") (serialize-qp "fields[campaign]" $fieldscampaign "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaigns/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Campaign
#
# PATCH /api/campaigns/{id}
# operationId: update_campaign
export def "campaigns campaign-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign]" $fieldscampaign "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaigns/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Campaign
#
# DELETE /api/campaigns/{id}
# operationId: delete_campaign
export def "campaigns campaign-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Campaign Message
#
# GET /api/campaign-messages/{id}
# operationId: get_campaign_message
export def "campaign-messages message-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv") (serialize-qp "fields[campaign]" $fieldscampaign "csv") (serialize-qp "fields[image]" $fieldsimage "csv") (serialize-qp "fields[template]" $fieldstemplate "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-messages/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Campaign Message
#
# PATCH /api/campaign-messages/{id}
# operationId: update_campaign_message
export def "campaign-messages message-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-messages/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Campaign Send Job
#
# GET /api/campaign-send-jobs/{id}
# operationId: get_campaign_send_job
export def "campaign-send-jobs job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-send-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-send-job]" $fieldscampaign_send_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-send-jobs/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel Campaign Send
#
# PATCH /api/campaign-send-jobs/{id}
# operationId: cancel_campaign_send
export def "campaign-send-jobs send" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaign-send-jobs/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Campaign Recipient Estimation Job
#
# GET /api/campaign-recipient-estimation-jobs/{id}
# operationId: get_campaign_recipient_estimation_job
export def "campaign-recipient-estimation-jobs job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-recipient-estimation-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-recipient-estimation-job]" $fieldscampaign_recipient_estimation_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-recipient-estimation-jobs/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Campaign Recipient Estimation
#
# GET /api/campaign-recipient-estimations/{id}
# operationId: get_campaign_recipient_estimation
export def "campaign-recipient-estimations estimation" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-recipient-estimation: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-recipient-estimation]" $fieldscampaign_recipient_estimation "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-recipient-estimations/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Campaign Clone
#
# POST /api/campaign-clone
# operationId: create_campaign_clone
export def "campaign-clone clone" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign]" $fieldscampaign "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaign-clone" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Assign Template to Campaign Message
#
# POST /api/campaign-message-assign-template
# operationId: assign_template_to_campaign_message
export def "campaign-message-assign-template message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaign-message-assign-template" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Send Campaign
#
# POST /api/campaign-send-jobs
# operationId: send_campaign
export def "campaign-send-jobs campaign" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-send-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-send-job]" $fieldscampaign_send_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaign-send-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Refresh Campaign Recipient Estimation
#
# POST /api/campaign-recipient-estimation-jobs
# operationId: refresh_campaign_recipient_estimation
export def "campaign-recipient-estimation-jobs estimation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-recipient-estimation-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-recipient-estimation-job]" $fieldscampaign_recipient_estimation_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaign-recipient-estimation-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Campaign for Campaign Message
#
# GET /api/campaign-messages/{id}/campaign
# operationId: get_campaign_for_campaign_message
export def "campaign-messages-campaign message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign]" $fieldscampaign "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-messages/($id)/campaign" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Campaign ID for Campaign Message
#
# GET /api/campaign-messages/{id}/relationships/campaign
# operationId: get_campaign_id_for_campaign_message
export def "campaign-messages-relationships-campaign message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaign-messages/($id)/relationships/campaign")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Template for Campaign Message
#
# GET /api/campaign-messages/{id}/template
# operationId: get_template_for_campaign_message
export def "campaign-messages-template message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-messages/($id)/template" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Template ID for Campaign Message
#
# GET /api/campaign-messages/{id}/relationships/template
# operationId: get_template_id_for_campaign_message
export def "campaign-messages-relationships-template message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaign-messages/($id)/relationships/template")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Image for Campaign Message
#
# GET /api/campaign-messages/{id}/image
# operationId: get_image_for_campaign_message
export def "campaign-messages-image message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaign-messages/($id)/image" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Image ID for Campaign Message
#
# GET /api/campaign-messages/{id}/relationships/image
# operationId: get_image_id_for_campaign_message
export def "campaign-messages-relationships-image message-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaign-messages/($id)/relationships/image")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Image for Campaign Message
#
# PATCH /api/campaign-messages/{id}/relationships/image
# operationId: update_image_for_campaign_message
export def "campaign-messages-relationships-image message-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaign-messages/($id)/relationships/image")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Tags for Campaign
#
# GET /api/campaigns/{id}/tags
# operationId: get_tags_for_campaign
export def "campaigns-tags campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaigns/($id)/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag IDs for Campaign
#
# GET /api/campaigns/{id}/relationships/tags
# operationId: get_tag_ids_for_campaign
export def "campaigns-relationships-tags campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($id)/relationships/tags")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Messages for Campaign
#
# GET /api/campaigns/{id}/campaign-messages
# operationId: get_messages_for_campaign
export def "campaigns-campaign-messages campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscampaign: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-message]" $fieldscampaign_message "csv") (serialize-qp "fields[campaign]" $fieldscampaign "csv") (serialize-qp "fields[image]" $fieldsimage "csv") (serialize-qp "fields[template]" $fieldstemplate "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/campaigns/($id)/campaign-messages" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Message IDs for Campaign
#
# GET /api/campaigns/{id}/relationships/campaign-messages
# operationId: get_message_ids_for_campaign
export def "campaigns-relationships-campaign-messages campaign" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/campaigns/($id)/relationships/campaign-messages")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Catalog Items
#
# GET /api/catalog-items
# operationId: get_catalog_items
export def "catalog-items items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`category.id`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1']))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv") (serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-items" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Catalog Item
#
# POST /api/catalog-items
# operationId: create_catalog_item
export def "catalog-items item" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-items" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Catalog Item
#
# GET /api/catalog-items/{id}
# operationId: get_catalog_item
export def "catalog-items item-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv") (serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Catalog Item
#
# PATCH /api/catalog-items/{id}
# operationId: update_catalog_item
export def "catalog-items item-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Catalog Item
#
# DELETE /api/catalog-items/{id}
# operationId: delete_catalog_item
export def "catalog-items item-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-items/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Catalog Variants
#
# GET /api/catalog-variants
# operationId: get_catalog_variants
export def "catalog-variants variants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`sku`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1-VARIANT-MEDIUM']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variants" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Catalog Variant
#
# POST /api/catalog-variants
# operationId: create_catalog_variant
export def "catalog-variants variant" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variants" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Catalog Variant
#
# GET /api/catalog-variants/{id}
# operationId: get_catalog_variant
export def "catalog-variants variant-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-variants/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Catalog Variant
#
# PATCH /api/catalog-variants/{id}
# operationId: update_catalog_variant
export def "catalog-variants variant-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-variants/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Catalog Variant
#
# DELETE /api/catalog-variants/{id}
# operationId: delete_catalog_variant
export def "catalog-variants variant-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-variants/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Catalog Categories
#
# GET /api/catalog-categories
# operationId: get_catalog_categories
export def "catalog-categories categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`name`: `contains` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-CATEGORY-APPAREL']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-categories" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Catalog Category
#
# POST /api/catalog-categories
# operationId: create_catalog_category
export def "catalog-categories category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-categories" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Catalog Category
#
# GET /api/catalog-categories/{id}
# operationId: get_catalog_category
export def "catalog-categories category-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-categories/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Catalog Category
#
# PATCH /api/catalog-categories/{id}
# operationId: update_catalog_category
export def "catalog-categories category-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-categories/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Catalog Category
#
# DELETE /api/catalog-categories/{id}
# operationId: delete_catalog_category
export def "catalog-categories category-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-categories/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Create Catalog Items Jobs
#
# GET /api/catalog-item-bulk-create-jobs
# operationId: get_bulk_create_catalog_items_jobs
export def "catalog-item-bulk-create-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-create-job]" $fieldscatalog_item_bulk_create_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-create-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Catalog Items
#
# POST /api/catalog-item-bulk-create-jobs
# operationId: bulk_create_catalog_items
export def "catalog-item-bulk-create-jobs items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-create-job]" $fieldscatalog_item_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-create-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Create Catalog Items Job
#
# GET /api/catalog-item-bulk-create-jobs/{job_id}
# operationId: get_bulk_create_catalog_items_job
export def "catalog-item-bulk-create-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-create-job]" $fieldscatalog_item_bulk_create_job "csv") (serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-item-bulk-create-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Update Catalog Items Jobs
#
# GET /api/catalog-item-bulk-update-jobs
# operationId: get_bulk_update_catalog_items_jobs
export def "catalog-item-bulk-update-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-update-job]" $fieldscatalog_item_bulk_update_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-update-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Update Catalog Items
#
# POST /api/catalog-item-bulk-update-jobs
# operationId: bulk_update_catalog_items
export def "catalog-item-bulk-update-jobs items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-update-job]" $fieldscatalog_item_bulk_update_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-update-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Update Catalog Items Job
#
# GET /api/catalog-item-bulk-update-jobs/{job_id}
# operationId: get_bulk_update_catalog_items_job
export def "catalog-item-bulk-update-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-update-job]" $fieldscatalog_item_bulk_update_job "csv") (serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-item-bulk-update-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Delete Catalog Items Jobs
#
# GET /api/catalog-item-bulk-delete-jobs
# operationId: get_bulk_delete_catalog_items_jobs
export def "catalog-item-bulk-delete-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-delete-job]" $fieldscatalog_item_bulk_delete_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-delete-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Delete Catalog Items
#
# POST /api/catalog-item-bulk-delete-jobs
# operationId: bulk_delete_catalog_items
export def "catalog-item-bulk-delete-jobs items" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-delete-job]" $fieldscatalog_item_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-item-bulk-delete-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Delete Catalog Items Job
#
# GET /api/catalog-item-bulk-delete-jobs/{job_id}
# operationId: get_bulk_delete_catalog_items_job
export def "catalog-item-bulk-delete-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item-bulk-delete-job]" $fieldscatalog_item_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-item-bulk-delete-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Create Variants Jobs
#
# GET /api/catalog-variant-bulk-create-jobs
# operationId: get_bulk_create_variants_jobs
export def "catalog-variant-bulk-create-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-create-job]" $fieldscatalog_variant_bulk_create_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-create-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Catalog Variants
#
# POST /api/catalog-variant-bulk-create-jobs
# operationId: bulk_create_catalog_variants
export def "catalog-variant-bulk-create-jobs variants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-create-job]" $fieldscatalog_variant_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-create-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Create Variants Job
#
# GET /api/catalog-variant-bulk-create-jobs/{job_id}
# operationId: get_bulk_create_variants_job
export def "catalog-variant-bulk-create-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-create-job]" $fieldscatalog_variant_bulk_create_job "csv") (serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-variant-bulk-create-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Update Variants Jobs
#
# GET /api/catalog-variant-bulk-update-jobs
# operationId: get_bulk_update_variants_jobs
export def "catalog-variant-bulk-update-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-update-job]" $fieldscatalog_variant_bulk_update_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-update-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Update Catalog Variants
#
# POST /api/catalog-variant-bulk-update-jobs
# operationId: bulk_update_catalog_variants
export def "catalog-variant-bulk-update-jobs variants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-update-job]" $fieldscatalog_variant_bulk_update_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-update-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Update Variants Job
#
# GET /api/catalog-variant-bulk-update-jobs/{job_id}
# operationId: get_bulk_update_variants_job
export def "catalog-variant-bulk-update-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-update-job]" $fieldscatalog_variant_bulk_update_job "csv") (serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-variant-bulk-update-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Delete Variants Jobs
#
# GET /api/catalog-variant-bulk-delete-jobs
# operationId: get_bulk_delete_variants_jobs
export def "catalog-variant-bulk-delete-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-delete-job]" $fieldscatalog_variant_bulk_delete_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-delete-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Delete Catalog Variants
#
# POST /api/catalog-variant-bulk-delete-jobs
# operationId: bulk_delete_catalog_variants
export def "catalog-variant-bulk-delete-jobs variants" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-delete-job]" $fieldscatalog_variant_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-variant-bulk-delete-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Delete Variants Job
#
# GET /api/catalog-variant-bulk-delete-jobs/{job_id}
# operationId: get_bulk_delete_variants_job
export def "catalog-variant-bulk-delete-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant-bulk-delete-job]" $fieldscatalog_variant_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-variant-bulk-delete-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Create Categories Jobs
#
# GET /api/catalog-category-bulk-create-jobs
# operationId: get_bulk_create_categories_jobs
export def "catalog-category-bulk-create-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-create-job]" $fieldscatalog_category_bulk_create_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-create-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Catalog Categories
#
# POST /api/catalog-category-bulk-create-jobs
# operationId: bulk_create_catalog_categories
export def "catalog-category-bulk-create-jobs categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-create-job]" $fieldscatalog_category_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-create-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Create Categories Job
#
# GET /api/catalog-category-bulk-create-jobs/{job_id}
# operationId: get_bulk_create_categories_job
export def "catalog-category-bulk-create-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-create-job]" $fieldscatalog_category_bulk_create_job "csv") (serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-category-bulk-create-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Update Categories Jobs
#
# GET /api/catalog-category-bulk-update-jobs
# operationId: get_bulk_update_categories_jobs
export def "catalog-category-bulk-update-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-update-job]" $fieldscatalog_category_bulk_update_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-update-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Update Catalog Categories
#
# POST /api/catalog-category-bulk-update-jobs
# operationId: bulk_update_catalog_categories
export def "catalog-category-bulk-update-jobs categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-update-job]" $fieldscatalog_category_bulk_update_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-update-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Update Categories Job
#
# GET /api/catalog-category-bulk-update-jobs/{job_id}
# operationId: get_bulk_update_categories_job
export def "catalog-category-bulk-update-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-update-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-update-job]" $fieldscatalog_category_bulk_update_job "csv") (serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-category-bulk-update-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Delete Categories Jobs
#
# GET /api/catalog-category-bulk-delete-jobs
# operationId: get_bulk_delete_categories_jobs
export def "catalog-category-bulk-delete-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-delete-job]" $fieldscatalog_category_bulk_delete_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-delete-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Delete Catalog Categories
#
# POST /api/catalog-category-bulk-delete-jobs
# operationId: bulk_delete_catalog_categories
export def "catalog-category-bulk-delete-jobs categories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-delete-job]" $fieldscatalog_category_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/catalog-category-bulk-delete-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Delete Categories Job
#
# GET /api/catalog-category-bulk-delete-jobs/{job_id}
# operationId: get_bulk_delete_categories_job
export def "catalog-category-bulk-delete-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category-bulk-delete-job]" $fieldscatalog_category_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-category-bulk-delete-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Back In Stock Subscription
#
# POST /api/back-in-stock-subscriptions
# operationId: create_back_in_stock_subscription
export def "back-in-stock-subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/back-in-stock-subscriptions")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Items for Catalog Category
#
# GET /api/catalog-categories/{id}/items
# operationId: get_items_for_catalog_category
export def "catalog-categories-items category" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-item: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`category.id`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1']))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-item]" $fieldscatalog_item "csv") (serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-categories/($id)/items" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Item IDs for Catalog Category
#
# GET /api/catalog-categories/{id}/relationships/items
# operationId: get_item_ids_for_catalog_category
export def "catalog-categories-relationships-items category-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`category.id`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-categories/($id)/relationships/items" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Items to Catalog Category
#
# POST /api/catalog-categories/{id}/relationships/items
# operationId: add_items_to_catalog_category
export def "catalog-categories-relationships-items category-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-categories/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Update Items for Catalog Category
#
# PATCH /api/catalog-categories/{id}/relationships/items
# operationId: update_items_for_catalog_category
export def "catalog-categories-relationships-items category-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-categories/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Items from Catalog Category
#
# DELETE /api/catalog-categories/{id}/relationships/items
# operationId: remove_items_from_catalog_category
export def "catalog-categories-relationships-items category-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-categories/($id)/relationships/items")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Variants for Catalog Item
#
# GET /api/catalog-items/{id}/variants
# operationId: get_variants_for_catalog_item
export def "catalog-items-variants item" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-variant: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`sku`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1-VARIANT-MEDIUM']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-variant]" $fieldscatalog_variant "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)/variants" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Variant IDs for Catalog Item
#
# GET /api/catalog-items/{id}/relationships/variants
# operationId: get_variant_ids_for_catalog_item
export def "catalog-items-relationships-variants item" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`sku`: `equals`<br>`title`: `contains`<br>`published`: `equals` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-ITEM-1-VARIANT-MEDIUM']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)/relationships/variants" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Categories for Catalog Item
#
# GET /api/catalog-items/{id}/categories
# operationId: get_categories_for_catalog_item
export def "catalog-items-categories item" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscatalog-category: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`name`: `contains` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-CATEGORY-APPAREL']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[catalog-category]" $fieldscatalog_category "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)/categories" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Category IDs for Catalog Item
#
# GET /api/catalog-items/{id}/relationships/categories
# operationId: get_category_ids_for_catalog_item
export def "catalog-items-relationships-categories item-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`ids`: `any`<br>`item.id`: `equals`<br>`name`: `contains` (e.g. any(ids,['$custom:::$default:::SAMPLE-DATA-CATEGORY-APPAREL']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/catalog-items/($id)/relationships/categories" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Categories to Catalog Item
#
# POST /api/catalog-items/{id}/relationships/categories
# operationId: add_categories_to_catalog_item
export def "catalog-items-relationships-categories item-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-items/($id)/relationships/categories")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Update Categories for Catalog Item
#
# PATCH /api/catalog-items/{id}/relationships/categories
# operationId: update_categories_for_catalog_item
export def "catalog-items-relationships-categories item-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-items/($id)/relationships/categories")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Categories from Catalog Item
#
# DELETE /api/catalog-items/{id}/relationships/categories
# operationId: remove_categories_from_catalog_item
export def "catalog-items-relationships-categories item-by-id-3" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/catalog-items/($id)/relationships/categories")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create Conversation Message
#
# POST /api/conversation-messages
# operationId: create_conversation_message
export def "conversation-messages message" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/conversation-messages")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Coupons
#
# GET /api/coupons
# operationId: get_coupons
export def "coupons coupons" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon]" $fieldscoupon "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupons" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Coupon
#
# POST /api/coupons
# operationId: create_coupon
export def "coupons coupon" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon]" $fieldscoupon "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupons" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Coupon
#
# GET /api/coupons/{id}
# operationId: get_coupon
export def "coupons coupon-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon]" $fieldscoupon "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupons/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Coupon
#
# PATCH /api/coupons/{id}
# operationId: update_coupon
export def "coupons coupon-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon]" $fieldscoupon "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupons/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Coupon
#
# DELETE /api/coupons/{id}
# operationId: delete_coupon
export def "coupons coupon-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/coupons/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Coupon Codes
#
# GET /api/coupon-codes
# operationId: get_coupon_codes
export def "coupon-codes codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`expires_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`status`: `equals`<br>`coupon.id`: `any`, `equals`<br>`profile.id`: `any`, `equals` (e.g. equals(coupon.id,'10OFF'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv") (serialize-qp "fields[coupon]" $fieldscoupon "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupon-codes" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Coupon Code
#
# POST /api/coupon-codes
# operationId: create_coupon_code
export def "coupon-codes code" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupon-codes" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Coupon Code
#
# GET /api/coupon-codes/{id}
# operationId: get_coupon_code
export def "coupon-codes code-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv") (serialize-qp "fields[coupon]" $fieldscoupon "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupon-codes/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Coupon Code
#
# PATCH /api/coupon-codes/{id}
# operationId: update_coupon_code
export def "coupon-codes code-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupon-codes/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Coupon Code
#
# DELETE /api/coupon-codes/{id}
# operationId: delete_coupon_code
export def "coupon-codes code-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/coupon-codes/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Create Coupon Code Jobs
#
# GET /api/coupon-code-bulk-create-jobs
# operationId: get_bulk_create_coupon_code_jobs
export def "coupon-code-bulk-create-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code-bulk-create-job]" $fieldscoupon_code_bulk_create_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupon-code-bulk-create-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Coupon Codes
#
# POST /api/coupon-code-bulk-create-jobs
# operationId: bulk_create_coupon_codes
export def "coupon-code-bulk-create-jobs codes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code-bulk-create-job]" $fieldscoupon_code_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/coupon-code-bulk-create-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Create Coupon Codes Job
#
# GET /api/coupon-code-bulk-create-jobs/{job_id}
# operationId: get_bulk_create_coupon_codes_job
export def "coupon-code-bulk-create-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code-bulk-create-job]" $fieldscoupon_code_bulk_create_job "csv") (serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupon-code-bulk-create-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Coupon For Coupon Code
#
# GET /api/coupon-codes/{id}/coupon
# operationId: get_coupon_for_coupon_code
export def "coupon-codes-coupon code" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon]" $fieldscoupon "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupon-codes/($id)/coupon" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Coupon ID for Coupon Code
#
# GET /api/coupon-codes/{id}/relationships/coupon
# operationId: get_coupon_id_for_coupon_code
export def "coupon-codes-relationships-coupon code" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/coupon-codes/($id)/relationships/coupon")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Coupon Codes for Coupon
#
# GET /api/coupons/{id}/coupon-codes
# operationId: get_coupon_codes_for_coupon
export def "coupons-coupon-codes coupon" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscoupon-code: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`expires_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`status`: `equals`<br>`coupon.id`: `any`, `equals`<br>`profile.id`: `any`, `equals` (e.g. less-than(expires_at,2022-11-08T00:00:00+00:00))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[coupon-code]" $fieldscoupon_code "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupons/($id)/coupon-codes" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Coupon Code IDs for Coupon
#
# GET /api/coupons/{id}/relationships/coupon-codes
# operationId: get_coupon_code_ids_for_coupon
export def "coupons-relationships-coupon-codes coupon" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`expires_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`status`: `equals`<br>`coupon.id`: `any`, `equals`<br>`profile.id`: `any`, `equals` (e.g. less-than(expires_at,2022-11-08T00:00:00+00:00))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 100. Min: 1. Max: 100. (default: 100)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/coupons/($id)/relationships/coupon-codes" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Data Sources
#
# GET /api/data-sources
# operationId: get_data_sources
export def "data-sources sources" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsdata-source: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[data-source]" $fieldsdata_source "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/data-sources" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Data Source
#
# POST /api/data-sources
# operationId: create_data_source
export def "data-sources source" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsdata-source: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[data-source]" $fieldsdata_source "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/data-sources" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Data Source
#
# GET /api/data-sources/{id}
# operationId: get_data_source
export def "data-sources source-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsdata-source: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[data-source]" $fieldsdata_source "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/data-sources/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Data Source
#
# DELETE /api/data-sources/{id}
# operationId: delete_data_source
export def "data-sources source-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/data-sources/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Data Source Records
#
# POST /api/data-source-record-bulk-create-jobs
# operationId: bulk_create_data_source_records
export def "data-source-record-bulk-create-jobs records" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-source-record-bulk-create-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create Data Source Record
#
# POST /api/data-source-record-create-jobs
# operationId: create_data_source_record
export def "data-source-record-create-jobs record" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-source-record-create-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Request Profile Deletion
#
# POST /api/data-privacy-deletion-jobs
# operationId: request_profile_deletion
export def "data-privacy-deletion-jobs deletion" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/data-privacy-deletion-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Events
#
# GET /api/events
# operationId: get_events
export def "events events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsattribution: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsevent: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`metric_id`: `equals`<br>`profile_id`: `equals`<br>`profile`: `has`<br>`datetime`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`timestamp`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(metric_id,'example'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 200. Min: 1. Max: 1000. (default: 200)
  --qp-sort: string@sort-completer-2 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[attribution]" $fieldsattribution "csv") (serialize-qp "fields[event]" $fieldsevent "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/events" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Event
#
# POST /api/events
# operationId: create_event
export def "events event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/events")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Event
#
# GET /api/events/{id}
# operationId: get_event
export def "events event-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsattribution: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsevent: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[attribution]" $fieldsattribution "csv") (serialize-qp "fields[event]" $fieldsevent "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/events/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Create Events
#
# POST /api/event-bulk-create-jobs
# operationId: bulk_create_events
export def "event-bulk-create-jobs events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/event-bulk-create-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Metric for Event
#
# GET /api/events/{id}/metric
# operationId: get_metric_for_event
export def "events-metric event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[metric]" $fieldsmetric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/events/($id)/metric" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric ID for Event
#
# GET /api/events/{id}/relationships/metric
# operationId: get_metric_id_for_event
export def "events-relationships-metric event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/events/($id)/relationships/metric")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile for Event
#
# GET /api/events/{id}/profile
# operationId: get_profile_for_event
export def "events-profile event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/events/($id)/profile" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile ID for Event
#
# GET /api/events/{id}/relationships/profile
# operationId: get_profile_id_for_event
export def "events-relationships-profile event" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/events/($id)/relationships/profile")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flows
#
# GET /api/flows
# operationId: get_flows
export def "flows flows" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`<br>`name`: `contains`, `ends-with`, `equals`, `starts-with`<br>`status`: `equals`<br>`archived`: `equals`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`trigger_type`: `equals` (e.g. any(id,['example']))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-3 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv") (serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/flows" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Flow
#
# POST /api/flows
# operationId: create_flow
export def "flows flow" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsflow: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[flow]" $additional_fieldsflow "csv") (serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/flows" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Flow
#
# GET /api/flows/{id}
# operationId: get_flow
export def "flows flow-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsflow: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[flow]" $additional_fieldsflow "csv") (serialize-qp "fields[flow-action]" $fieldsflow_action "csv") (serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flows/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Flow Status
#
# PATCH /api/flows/{id}
# operationId: update_flow
export def "flows flow-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flows/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Flow
#
# DELETE /api/flows/{id}
# operationId: delete_flow
export def "flows flow-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/flows/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flow Action
#
# GET /api/flow-actions/{id}
# operationId: get_flow_action
export def "flow-actions action-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsflow-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv") (serialize-qp "fields[flow-message]" $fieldsflow_message "csv") (serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-actions/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Flow Action
#
# PATCH /api/flow-actions/{id}
# operationId: update_flow_action
export def "flow-actions action-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-actions/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Flow Message
#
# GET /api/flow-messages/{id}
# operationId: get_flow_message
export def "flow-messages message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsflow-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv") (serialize-qp "fields[flow-message]" $fieldsflow_message "csv") (serialize-qp "fields[template]" $fieldstemplate "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-messages/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Actions for Flow
#
# GET /api/flows/{id}/flow-actions
# operationId: get_actions_for_flow
export def "flows-flow-actions flow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`<br>`action_type`: `any`, `equals`<br>`status`: `equals`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. any(id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-4 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flows/($id)/flow-actions" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Action IDs for Flow
#
# GET /api/flows/{id}/relationships/flow-actions
# operationId: get_action_ids_for_flow
export def "flows-relationships-flow-actions flow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`<br>`action_type`: `any`, `equals`<br>`status`: `equals`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. any(id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-4 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flows/($id)/relationships/flow-actions" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags for Flow
#
# GET /api/flows/{id}/tags
# operationId: get_tags_for_flow
export def "flows-tags flow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flows/($id)/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag IDs for Flow
#
# GET /api/flows/{id}/relationships/tags
# operationId: get_tag_ids_for_flow
export def "flows-relationships-tags flow" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/flows/($id)/relationships/tags")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flow for Flow Action
#
# GET /api/flow-actions/{id}/flow
# operationId: get_flow_for_flow_action
export def "flow-actions-flow action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-actions/($id)/flow" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flow ID for Flow Action
#
# GET /api/flow-actions/{id}/relationships/flow
# operationId: get_flow_id_for_flow_action
export def "flow-actions-relationships-flow action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/flow-actions/($id)/relationships/flow")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Messages For Flow Action
#
# GET /api/flow-actions/{id}/flow-messages
# operationId: get_flow_action_messages
export def "flow-actions-flow-messages messages" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-message: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`<br>`name`: `contains`, `ends-with`, `equals`, `starts-with`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. any(id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-message]" $fieldsflow_message "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-actions/($id)/flow-messages" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Message IDs for Flow Action
#
# GET /api/flow-actions/{id}/relationships/flow-messages
# operationId: get_message_ids_for_flow_action
export def "flow-actions-relationships-flow-messages action" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `contains`, `ends-with`, `equals`, `starts-with`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(name,'example'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-actions/($id)/relationships/flow-messages" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Action for Flow Message
#
# GET /api/flow-messages/{id}/flow-action
# operationId: get_action_for_flow_message
export def "flow-messages-flow-action message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-action: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-action]" $fieldsflow_action "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-messages/($id)/flow-action" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Action ID for Flow Message
#
# GET /api/flow-messages/{id}/relationships/flow-action
# operationId: get_action_id_for_flow_message
export def "flow-messages-relationships-flow-action message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/flow-messages/($id)/relationships/flow-action")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Template for Flow Message
#
# GET /api/flow-messages/{id}/template
# operationId: get_template_for_flow_message
export def "flow-messages-template message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/flow-messages/($id)/template" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Template ID for Flow Message
#
# GET /api/flow-messages/{id}/relationships/template
# operationId: get_template_id_for_flow_message
export def "flow-messages-relationships-template message" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/flow-messages/($id)/relationships/template")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Forms
#
# GET /api/forms
# operationId: get_forms
export def "forms forms" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`, `equals`<br>`name`: `any`, `contains`, `equals`<br>`ab_test`: `equals`<br>`updated_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`created_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`status`: `equals` (e.g. equals(id,'Y6nRLr'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-6 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form]" $fieldsform "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/forms" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Form
#
# POST /api/forms
# operationId: create_form
export def "forms form" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form]" $fieldsform "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/forms" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Form
#
# GET /api/forms/{id}
# operationId: get_form
export def "forms form-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form]" $fieldsform "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/forms/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Form
#
# DELETE /api/forms/{id}
# operationId: delete_form
export def "forms form-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/forms/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Form Version
#
# GET /api/form-versions/{id}
# operationId: get_form_version
export def "form-versions version" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform-version: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form-version]" $fieldsform_version "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/form-versions/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Versions for Form
#
# GET /api/forms/{id}/form-versions
# operationId: get_versions_for_form
export def "forms-form-versions form" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform-version: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`form_type`: `any`, `equals`<br>`status`: `equals`<br>`updated_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`created_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(form_type,'popup'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-6 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form-version]" $fieldsform_version "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/forms/($id)/form-versions" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Version IDs for Form
#
# GET /api/forms/{id}/relationships/form-versions
# operationId: get_version_ids_for_form
export def "forms-relationships-form-versions form" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`form_type`: `any`, `equals`<br>`status`: `equals`<br>`updated_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`created_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(form_type,'popup'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-6 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/forms/($id)/relationships/form-versions" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Form for Form Version
#
# GET /api/form-versions/{id}/form
# operationId: get_form_for_form_version
export def "form-versions-form version" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form]" $fieldsform "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/form-versions/($id)/form" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Form ID for Form Version
#
# GET /api/form-versions/{id}/relationships/form
# operationId: get_form_id_for_form_version
export def "form-versions-relationships-form version" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/form-versions/($id)/relationships/form")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Images
#
# GET /api/images
# operationId: get_images
export def "images images" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`, `equals`<br>`updated_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`format`: `any`, `equals`<br>`name`: `any`, `contains`, `ends-with`, `equals`, `starts-with`<br>`size`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`hidden`: `any`, `equals` (e.g. equals(id,'7'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-7 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/images" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Upload Image From URL
#
# POST /api/images
# operationId: upload_image_from_url
export def "images url" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/images" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Image
#
# GET /api/images/{id}
# operationId: get_image
export def "images image-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/images/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Image
#
# PATCH /api/images/{id}
# operationId: update_image
export def "images image-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/images/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Upload Image From File
#
# POST /api/image-upload
# operationId: upload_image_from_file
export def "image-upload file" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimage: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  file: string # The image file to upload. Supported image formats: jpeg,png,gif. Maximum image size: 5MB. (format: binary)
  --name: string # A name for the image.  Defaults to the filename if not provided.  If the name matches an existing image, a suffix will be added.
  --hidden: oneof<nothing, bool> # If true, this image is not shown in the asset library. (default: false)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[image]" $fieldsimage "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/image-upload" $qp)
  let body = {file: $file, name: $name, hidden: $hidden} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# Get Lists
#
# GET /api/lists
# operationId: get_lists
export def "lists lists" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `any`, `equals`<br>`id`: `any`, `equals`<br>`created`: `greater-than`<br>`updated`: `greater-than` (e.g. equals(name,['example']))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 10. Min: 1. Max: 10. (default: 10)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[list]" $fieldslist "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create List
#
# POST /api/lists
# operationId: create_list
export def "lists list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[list]" $fieldslist "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/lists" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get List
#
# GET /api/lists/{id}
# operationId: get_list
export def "lists list-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldslist: list # Request additional fields not included by default in the response. Supported values: 'profile_count'
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[list]" $additional_fieldslist "csv") (serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[list]" $fieldslist "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update List
#
# PATCH /api/lists/{id}
# operationId: update_list
export def "lists list-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[list]" $fieldslist "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete List
#
# DELETE /api/lists/{id}
# operationId: delete_list
export def "lists list-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags for List
#
# GET /api/lists/{id}/tags
# operationId: get_tags_for_list
export def "lists-tags list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag IDs for List
#
# GET /api/lists/{id}/relationships/tags
# operationId: get_tag_ids_for_list
export def "lists-relationships-tags list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($id)/relationships/tags")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profiles for List
#
# GET /api/lists/{id}/profiles
# operationId: get_profiles_for_list
export def "lists-profiles list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`email`: `any`, `equals`<br>`phone_number`: `any`, `equals`<br>`push_token`: `any`, `equals`<br>`_kx`: `equals`<br>`joined_group_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(email,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-8 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile IDs for List
#
# GET /api/lists/{id}/relationships/profiles
# operationId: get_profile_ids_for_list
export def "lists-relationships-profiles list-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`email`: `any`, `equals`<br>`phone_number`: `any`, `equals`<br>`push_token`: `any`, `equals`<br>`_kx`: `equals`<br>`joined_group_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(email,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-8 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)/relationships/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Profiles to List
#
# POST /api/lists/{id}/relationships/profiles
# operationId: add_profiles_to_list
export def "lists-relationships-profiles list-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($id)/relationships/profiles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Profiles from List
#
# DELETE /api/lists/{id}/relationships/profiles
# operationId: remove_profiles_from_list
export def "lists-relationships-profiles list-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($id)/relationships/profiles")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Flows Triggered by List
#
# GET /api/lists/{id}/flow-triggers
# operationId: get_flows_triggered_by_list
export def "lists-flow-triggers list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/lists/($id)/flow-triggers" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get IDs for Flows Triggered by List
#
# GET /api/lists/{id}/relationships/flow-triggers
# operationId: get_ids_for_flows_triggered_by_list
export def "lists-relationships-flow-triggers list" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/lists/($id)/relationships/flow-triggers")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metrics
#
# GET /api/metrics
# operationId: get_metrics
export def "metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`integration.name`: `equals`<br>`integration.category`: `equals` (e.g. equals(integration.name,'example'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/metrics" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric
#
# GET /api/metrics/{id}
# operationId: get_metric
export def "metrics metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metrics/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric Property
#
# GET /api/metric-properties/{id}
# operationId: get_metric_property
export def "metric-properties property" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsmetric-property: list # Request additional fields not included by default in the response. Supported values: 'sample_values'
  --fieldsmetric-property: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[metric-property]" $additional_fieldsmetric_property "csv") (serialize-qp "fields[metric-property]" $fieldsmetric_property "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metric-properties/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Custom Metrics
#
# GET /api/custom-metrics
# operationId: get_custom_metrics
export def "custom-metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom-metrics" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Custom Metric
#
# POST /api/custom-metrics
# operationId: create_custom_metric
export def "custom-metrics metric" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/custom-metrics" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Custom Metric
#
# GET /api/custom-metrics/{id}
# operationId: get_custom_metric
export def "custom-metrics metric-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/custom-metrics/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Custom Metric
#
# PATCH /api/custom-metrics/{id}
# operationId: update_custom_metric
export def "custom-metrics metric-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/custom-metrics/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Custom Metric
#
# DELETE /api/custom-metrics/{id}
# operationId: delete_custom_metric
export def "custom-metrics metric-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/custom-metrics/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mapped Metrics
#
# GET /api/mapped-metrics
# operationId: get_mapped_metrics
export def "mapped-metrics metrics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmapped-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv") (serialize-qp "fields[mapped-metric]" $fieldsmapped_metric "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/mapped-metrics" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Mapped Metric
#
# GET /api/mapped-metrics/{id}
# operationId: get_mapped_metric
export def "mapped-metrics metric-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmapped-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv") (serialize-qp "fields[mapped-metric]" $fieldsmapped_metric "csv") (serialize-qp "fields[metric]" $fieldsmetric "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/mapped-metrics/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Mapped Metric
#
# PATCH /api/mapped-metrics/{id}
# operationId: update_mapped_metric
export def "mapped-metrics metric-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmapped-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[mapped-metric]" $fieldsmapped_metric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/mapped-metrics/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Metric Aggregates
#
# POST /api/metric-aggregates
# operationId: query_metric_aggregates
export def "metric-aggregates aggregates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmetric-aggregate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[metric-aggregate]" $fieldsmetric_aggregate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/metric-aggregates" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Flows Triggered by Metric
#
# GET /api/metrics/{id}/flow-triggers
# operationId: get_flows_triggered_by_metric
export def "metrics-flow-triggers metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metrics/($id)/flow-triggers" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get IDs for Flows Triggered by Metric
#
# GET /api/metrics/{id}/relationships/flow-triggers
# operationId: get_ids_for_flows_triggered_by_metric
export def "metrics-relationships-flow-triggers metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metrics/($id)/relationships/flow-triggers")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Properties for Metric
#
# GET /api/metrics/{id}/metric-properties
# operationId: get_properties_for_metric
export def "metrics-metric-properties metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsmetric-property: list # Request additional fields not included by default in the response. Supported values: 'sample_values'
  --fieldsmetric-property: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[metric-property]" $additional_fieldsmetric_property "csv") (serialize-qp "fields[metric-property]" $fieldsmetric_property "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metrics/($id)/metric-properties" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Property IDs for Metric
#
# GET /api/metrics/{id}/relationships/metric-properties
# operationId: get_property_ids_for_metric
export def "metrics-relationships-metric-properties metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metrics/($id)/relationships/metric-properties")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric for Metric Property
#
# GET /api/metric-properties/{id}/metric
# operationId: get_metric_for_metric_property
export def "metric-properties-metric property" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[metric]" $fieldsmetric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/metric-properties/($id)/metric" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric ID for Metric Property
#
# GET /api/metric-properties/{id}/relationships/metric
# operationId: get_metric_id_for_metric_property
export def "metric-properties-relationships-metric property" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/metric-properties/($id)/relationships/metric")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metrics for Custom Metric
#
# GET /api/custom-metrics/{id}/metrics
# operationId: get_metrics_for_custom_metric
export def "custom-metrics-metrics metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[metric]" $fieldsmetric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/custom-metrics/($id)/metrics" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric IDs for Custom Metric
#
# GET /api/custom-metrics/{id}/relationships/metrics
# operationId: get_metric_ids_for_custom_metric
export def "custom-metrics-relationships-metrics metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/custom-metrics/($id)/relationships/metrics")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric for Mapped Metric
#
# GET /api/mapped-metrics/{id}/metric
# operationId: get_metric_for_mapped_metric
export def "mapped-metrics-metric metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsmetric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[metric]" $fieldsmetric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/mapped-metrics/($id)/metric" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Metric ID for Mapped Metric
#
# GET /api/mapped-metrics/{id}/relationships/metric
# operationId: get_metric_id_for_mapped_metric
export def "mapped-metrics-relationships-metric metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/mapped-metrics/($id)/relationships/metric")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Custom Metric for Mapped Metric
#
# GET /api/mapped-metrics/{id}/custom-metric
# operationId: get_custom_metric_for_mapped_metric
export def "mapped-metrics-custom-metric metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscustom-metric: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[custom-metric]" $fieldscustom_metric "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/mapped-metrics/($id)/custom-metric" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Custom Metric ID for Mapped Metric
#
# GET /api/mapped-metrics/{id}/relationships/custom-metric
# operationId: get_custom_metric_id_for_mapped_metric
export def "mapped-metrics-relationships-custom-metric metric" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/mapped-metrics/($id)/relationships/custom-metric")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profiles
#
# GET /api/profiles
# operationId: get_profiles
export def "profiles profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsconversation: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldspush-token: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`, `equals`<br>`email`: `any`, `equals`<br>`phone_number`: `any`, `equals`<br>`external_id`: `any`, `equals`<br>`_kx`: `equals`<br>`created`: `greater-than`, `less-than`<br>`updated`: `greater-than`, `less-than`<br>`subscriptions.email.marketing.list_suppressions.reason`: `equals`<br>`subscriptions.email.marketing.list_suppressions.timestamp`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`subscriptions.email.marketing.list_suppressions.list_id`: `equals`<br>`subscriptions.email.marketing.suppression.reason`: `equals`<br>`subscriptions.email.marketing.suppression.timestamp`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(id,'example'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-9 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[conversation]" $fieldsconversation "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "fields[push-token]" $fieldspush_token "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Profile
#
# POST /api/profiles
# operationId: create_profile
export def "profiles profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profiles" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Profile
#
# GET /api/profiles/{id}
# operationId: get_profile
export def "profiles profile-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsconversation: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldspush-token: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[conversation]" $fieldsconversation "csv") (serialize-qp "fields[list]" $fieldslist "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "fields[push-token]" $fieldspush_token "csv") (serialize-qp "fields[segment]" $fieldssegment "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Profile
#
# PATCH /api/profiles/{id}
# operationId: update_profile
export def "profiles profile-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Import Profiles Jobs
#
# GET /api/profile-bulk-import-jobs
# operationId: get_bulk_import_profiles_jobs
export def "profile-bulk-import-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-bulk-import-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `any`, `equals` (e.g. equals(status,'queued'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-10 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-bulk-import-job]" $fieldsprofile_bulk_import_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-bulk-import-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Import Profiles
#
# POST /api/profile-bulk-import-jobs
# operationId: bulk_import_profiles
export def "profile-bulk-import-jobs profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-bulk-import-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-bulk-import-job]" $fieldsprofile_bulk_import_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-bulk-import-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{job_id}
# operationId: get_bulk_import_profiles_job
export def "profile-bulk-import-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsprofile-bulk-import-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[list]" $fieldslist "csv") (serialize-qp "fields[profile-bulk-import-job]" $fieldsprofile_bulk_import_job "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Suppress Profiles Jobs
#
# GET /api/profile-suppression-bulk-create-jobs
# operationId: get_bulk_suppress_profiles_jobs
export def "profile-suppression-bulk-create-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals`<br>`list_id`: `equals`<br>`segment_id`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-create-job]" $fieldsprofile_suppression_bulk_create_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-suppression-bulk-create-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Suppress Profiles
#
# POST /api/profile-suppression-bulk-create-jobs
# operationId: bulk_suppress_profiles
export def "profile-suppression-bulk-create-jobs profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-create-job]" $fieldsprofile_suppression_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-suppression-bulk-create-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Suppress Profiles Job
#
# GET /api/profile-suppression-bulk-create-jobs/{job_id}
# operationId: get_bulk_suppress_profiles_job
export def "profile-suppression-bulk-create-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-create-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-create-job]" $fieldsprofile_suppression_bulk_create_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-suppression-bulk-create-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Bulk Unsuppress Profiles Jobs
#
# GET /api/profile-suppression-bulk-delete-jobs
# operationId: get_bulk_unsuppress_profiles_jobs
export def "profile-suppression-bulk-delete-jobs jobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals`<br>`list_id`: `equals`<br>`segment_id`: `equals` (e.g. equals(status,'processing'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --qp-sort: string@sort-completer-1 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-delete-job]" $fieldsprofile_suppression_bulk_delete_job "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-suppression-bulk-delete-jobs" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Bulk Unsuppress Profiles
#
# POST /api/profile-suppression-bulk-delete-jobs
# operationId: bulk_unsuppress_profiles
export def "profile-suppression-bulk-delete-jobs profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-delete-job]" $fieldsprofile_suppression_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-suppression-bulk-delete-jobs" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Bulk Unsuppress Profiles Job
#
# GET /api/profile-suppression-bulk-delete-jobs/{job_id}
# operationId: get_bulk_unsuppress_profiles_job
export def "profile-suppression-bulk-delete-jobs job" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile-suppression-bulk-delete-job: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile-suppression-bulk-delete-job]" $fieldsprofile_suppression_bulk_delete_job "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-suppression-bulk-delete-jobs/($job_id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Push Tokens
#
# GET /api/push-tokens
# operationId: get_push_tokens
export def "push-tokens tokens" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldspush-token: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `equals`<br>`profile.id`: `equals`<br>`enablement_status`: `equals`<br>`platform`: `equals` (e.g. equals(id,'example'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "fields[push-token]" $fieldspush_token "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/push-tokens" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Push Token
#
# POST /api/push-tokens
# operationId: create_push_token
export def "push-tokens token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/push-tokens")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Push Token
#
# GET /api/push-tokens/{id}
# operationId: get_push_token
export def "push-tokens token-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldspush-token: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "fields[push-token]" $fieldspush_token "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/push-tokens/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Push Token
#
# DELETE /api/push-tokens/{id}
# operationId: delete_push_token
export def "push-tokens token-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/push-tokens/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Update Profile
#
# POST /api/profile-import
# operationId: create_or_update_profile
export def "profile-import profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-import" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Merge Profiles
#
# POST /api/profile-merge
# operationId: merge_profiles
export def "profile-merge profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/profile-merge" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Bulk Subscribe Profiles
#
# POST /api/profile-subscription-bulk-create-jobs
# operationId: bulk_subscribe_profiles
export def "profile-subscription-bulk-create-jobs profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/profile-subscription-bulk-create-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Bulk Unsubscribe Profiles
#
# POST /api/profile-subscription-bulk-delete-jobs
# operationId: bulk_unsubscribe_profiles
export def "profile-subscription-bulk-delete-jobs profiles" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/profile-subscription-bulk-delete-jobs")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Push Tokens for Profile
#
# GET /api/profiles/{id}/push-tokens
# operationId: get_push_tokens_for_profile
export def "profiles-push-tokens profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldspush-token: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[push-token]" $fieldspush_token "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)/push-tokens" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Push Token IDs for Profile
#
# GET /api/profiles/{id}/relationships/push-tokens
# operationId: get_push_token_ids_for_profile
export def "profiles-relationships-push-tokens profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profiles/($id)/relationships/push-tokens")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Lists for Profile
#
# GET /api/profiles/{id}/lists
# operationId: get_lists_for_profile
export def "profiles-lists profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[list]" $fieldslist "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)/lists" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List IDs for Profile
#
# GET /api/profiles/{id}/relationships/lists
# operationId: get_list_ids_for_profile
export def "profiles-relationships-lists profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profiles/($id)/relationships/lists")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Segments for Profile
#
# GET /api/profiles/{id}/segments
# operationId: get_segments_for_profile
export def "profiles-segments profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[segment]" $fieldssegment "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)/segments" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Segment IDs for Profile
#
# GET /api/profiles/{id}/relationships/segments
# operationId: get_segment_ids_for_profile
export def "profiles-relationships-segments profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profiles/($id)/relationships/segments")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Conversation for Profile
#
# GET /api/profiles/{id}/conversation
# operationId: get_conversation_for_profile
export def "profiles-conversation profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsconversation: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[conversation]" $fieldsconversation "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profiles/($id)/conversation" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Conversation ID for Profile
#
# GET /api/profiles/{id}/relationships/conversation
# operationId: get_conversation_id_for_profile
export def "profiles-relationships-conversation profile" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profiles/($id)/relationships/conversation")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List for Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{id}/lists
# operationId: get_list_for_bulk_import_profiles_job
export def "profile-bulk-import-jobs-lists job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldslist: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[list]" $fieldslist "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($id)/lists" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get List IDs for Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{id}/relationships/lists
# operationId: get_list_ids_for_bulk_import_profiles_job
export def "profile-bulk-import-jobs-relationships-lists job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($id)/relationships/lists")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profiles for Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{id}/profiles
# operationId: get_profiles_for_bulk_import_profiles_job
export def "profile-bulk-import-jobs-profiles job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($id)/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile IDs for Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{id}/relationships/profiles
# operationId: get_profile_ids_for_bulk_import_profiles_job
export def "profile-bulk-import-jobs-relationships-profiles job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($id)/relationships/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Errors for Bulk Import Profiles Job
#
# GET /api/profile-bulk-import-jobs/{id}/import-errors
# operationId: get_errors_for_bulk_import_profiles_job
export def "profile-bulk-import-jobs-import-errors job" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsimport-error: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[import-error]" $fieldsimport_error "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/profile-bulk-import-jobs/($id)/import-errors" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile for Push Token
#
# GET /api/push-tokens/{id}/profile
# operationId: get_profile_for_push_token
export def "push-tokens-profile token" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/push-tokens/($id)/profile" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile ID for Push Token
#
# GET /api/push-tokens/{id}/relationships/profile
# operationId: get_profile_id_for_push_token
export def "push-tokens-relationships-profile token" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/push-tokens/($id)/relationships/profile")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Query Campaign Values
#
# POST /api/campaign-values-reports
# operationId: query_campaign_values
export def "campaign-values-reports values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldscampaign-values-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --page-cursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[campaign-values-report]" $fieldscampaign_values_report "csv") (serialize-qp "page_cursor" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/campaign-values-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Flow Values
#
# POST /api/flow-values-reports
# operationId: query_flow_values
export def "flow-values-reports values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-values-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --page-cursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-values-report]" $fieldsflow_values_report "csv") (serialize-qp "page_cursor" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/flow-values-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Flow Series
#
# POST /api/flow-series-reports
# operationId: query_flow_series
export def "flow-series-reports series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow-series-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --page-cursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow-series-report]" $fieldsflow_series_report "csv") (serialize-qp "page_cursor" $page_cursor "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/flow-series-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Form Values
#
# POST /api/form-values-reports
# operationId: query_form_values
export def "form-values-reports values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform-values-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form-values-report]" $fieldsform_values_report "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/form-values-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Form Series
#
# POST /api/form-series-reports
# operationId: query_form_series
export def "form-series-reports series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsform-series-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[form-series-report]" $fieldsform_series_report "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/form-series-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Segment Values
#
# POST /api/segment-values-reports
# operationId: query_segment_values
export def "segment-values-reports values" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldssegment-values-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[segment-values-report]" $fieldssegment_values_report "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/segment-values-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Query Segment Series
#
# POST /api/segment-series-reports
# operationId: query_segment_series
export def "segment-series-reports series" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldssegment-series-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[segment-series-report]" $fieldssegment_series_report "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/segment-series-reports" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Reviews
#
# GET /api/reviews
# operationId: get_reviews
export def "reviews reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsevent: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsreview: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`created`: `greater-or-equal`, `less-or-equal`<br>`rating`: `any`, `equals`, `greater-or-equal`, `less-or-equal`<br>`id`: `any`, `equals`<br>`item.id`: `any`, `equals`<br>`content`: `contains`<br>`status`: `equals`<br>`review_type`: `equals`<br>`verified`: `equals` (e.g. less-or-equal(created,2022-11-08T00:00:00+00:00))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-11 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[event]" $fieldsevent "csv") (serialize-qp "fields[review]" $fieldsreview "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/reviews" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Review
#
# GET /api/reviews/{id}
# operationId: get_review
export def "reviews review-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsevent: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldsreview: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[event]" $fieldsevent "csv") (serialize-qp "fields[review]" $fieldsreview "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/reviews/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Review
#
# PATCH /api/reviews/{id}
# operationId: update_review
export def "reviews review-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsreview: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[review]" $fieldsreview "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/reviews/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Segments
#
# GET /api/segments
# operationId: get_segments
export def "segments segments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `any`, `equals`<br>`id`: `any`, `equals`<br>`created`: `greater-than`<br>`updated`: `greater-than`<br>`is_active`: `any`, `equals`<br>`is_starred`: `equals` (e.g. equals(name,['example']))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 10. Min: 1. Max: 10. (default: 10)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[segment]" $fieldssegment "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/segments" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Segment
#
# POST /api/segments
# operationId: create_segment
export def "segments segment" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[segment]" $fieldssegment "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/segments" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Segment
#
# GET /api/segments/{id}
# operationId: get_segment
export def "segments segment-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldssegment: list # Request additional fields not included by default in the response. Supported values: 'profile_count'
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[segment]" $additional_fieldssegment "csv") (serialize-qp "fields[flow]" $fieldsflow "csv") (serialize-qp "fields[segment]" $fieldssegment "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Segment
#
# PATCH /api/segments/{id}
# operationId: update_segment
export def "segments segment-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldssegment: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[segment]" $fieldssegment "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Segment
#
# DELETE /api/segments/{id}
# operationId: delete_segment
export def "segments segment-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags for Segment
#
# GET /api/segments/{id}/tags
# operationId: get_tags_for_segment
export def "segments-tags segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag IDs for Segment
#
# GET /api/segments/{id}/relationships/tags
# operationId: get_tag_ids_for_segment
export def "segments-relationships-tags segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)/relationships/tags")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profiles for Segment
#
# GET /api/segments/{id}/profiles
# operationId: get_profiles_for_segment
export def "segments-profiles segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldsprofile: list # Request additional fields not included by default in the response. Supported values: 'subscriptions', 'predictive_analytics'
  --fieldsprofile: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`profile_id`: `any`, `equals`<br>`email`: `any`, `equals`<br>`phone_number`: `any`, `equals`<br>`push_token`: `any`, `equals`<br>`_kx`: `equals`<br>`joined_group_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(profile_id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-8 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[profile]" $additional_fieldsprofile "csv") (serialize-qp "fields[profile]" $fieldsprofile "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Profile IDs for Segment
#
# GET /api/segments/{id}/relationships/profiles
# operationId: get_profile_ids_for_segment
export def "segments-relationships-profiles segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`profile_id`: `any`, `equals`<br>`email`: `any`, `equals`<br>`phone_number`: `any`, `equals`<br>`push_token`: `any`, `equals`<br>`_kx`: `equals`<br>`joined_group_at`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(profile_id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-8 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)/relationships/profiles" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flows Triggered by Segment
#
# GET /api/segments/{id}/flow-triggers
# operationId: get_flows_triggered_by_segment
export def "segments-flow-triggers segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsflow: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[flow]" $fieldsflow "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/segments/($id)/flow-triggers" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get IDs for Flows Triggered by Segment
#
# GET /api/segments/{id}/relationships/flow-triggers
# operationId: get_ids_for_flows_triggered_by_segment
export def "segments-relationships-flow-triggers segment" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/segments/($id)/relationships/flow-triggers")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags
#
# GET /api/tags
# operationId: get_tags
export def "tags tags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `contains`, `ends-with`, `equals`, `starts-with` (e.g. equals(name,'My Tag'))
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 50. Min: 1. Max: 50. (default: 50)
  --qp-sort: string@sort-completer-12 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "include" $include "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Tag
#
# POST /api/tags
# operationId: create_tag
export def "tags tag" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tags" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Tag
#
# GET /api/tags/{id}
# operationId: get_tag
export def "tags tag-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv") (serialize-qp "fields[tag]" $fieldstag "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tag
#
# PATCH /api/tags/{id}
# operationId: update_tag
export def "tags tag-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Tag
#
# DELETE /api/tags/{id}
# operationId: delete_tag
export def "tags tag-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag Groups
#
# GET /api/tag-groups
# operationId: get_tag_groups
export def "tag-groups groups" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `contains`, `ends-with`, `equals`, `starts-with`<br>`exclusive`: `equals`<br>`default`: `equals` (e.g. equals(name,'My Tag Group'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 25. Min: 1. Max: 25. (default: 25)
  --qp-sort: string@sort-completer-12 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tag-groups" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Tag Group
#
# POST /api/tag-groups
# operationId: create_tag_group
export def "tag-groups group" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tag-groups" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Tag Group
#
# GET /api/tag-groups/{id}
# operationId: get_tag_group
export def "tag-groups group-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tag-groups/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tag Group
#
# PATCH /api/tag-groups/{id}
# operationId: update_tag_group
export def "tag-groups group-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tag-groups/($id)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Tag Group
#
# DELETE /api/tag-groups/{id}
# operationId: delete_tag_group
export def "tag-groups group-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tag-groups/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Flow IDs for Tag
#
# GET /api/tags/{id}/relationships/flows
# operationId: get_flow_ids_for_tag
export def "tags-relationships-flows tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/flows")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag Flows
#
# POST /api/tags/{id}/relationships/flows
# operationId: tag_flows
export def "tags-relationships-flows flows-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/flows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Tag from Flows
#
# DELETE /api/tags/{id}/relationships/flows
# operationId: remove_tag_from_flows
export def "tags-relationships-flows flows-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/flows")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Campaign IDs for Tag
#
# GET /api/tags/{id}/relationships/campaigns
# operationId: get_campaign_ids_for_tag
export def "tags-relationships-campaigns tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/campaigns")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag Campaigns
#
# POST /api/tags/{id}/relationships/campaigns
# operationId: tag_campaigns
export def "tags-relationships-campaigns campaigns-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/campaigns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Tag from Campaigns
#
# DELETE /api/tags/{id}/relationships/campaigns
# operationId: remove_tag_from_campaigns
export def "tags-relationships-campaigns campaigns-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/campaigns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get List IDs for Tag
#
# GET /api/tags/{id}/relationships/lists
# operationId: get_list_ids_for_tag
export def "tags-relationships-lists tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/lists")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag Lists
#
# POST /api/tags/{id}/relationships/lists
# operationId: tag_lists
export def "tags-relationships-lists lists-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/lists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Tag from Lists
#
# DELETE /api/tags/{id}/relationships/lists
# operationId: remove_tag_from_lists
export def "tags-relationships-lists lists-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/lists")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Segment IDs for Tag
#
# GET /api/tags/{id}/relationships/segments
# operationId: get_segment_ids_for_tag
export def "tags-relationships-segments tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/segments")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Tag Segments
#
# POST /api/tags/{id}/relationships/segments
# operationId: tag_segments
export def "tags-relationships-segments segments-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/segments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Remove Tag from Segments
#
# DELETE /api/tags/{id}/relationships/segments
# operationId: remove_tag_from_segments
export def "tags-relationships-segments segments-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/segments")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Tag Group for Tag
#
# GET /api/tags/{id}/tag-group
# operationId: get_tag_group_for_tag
export def "tags-tag-group tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag-group: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag-group]" $fieldstag_group "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tags/($id)/tag-group" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag Group ID for Tag
#
# GET /api/tags/{id}/relationships/tag-group
# operationId: get_tag_group_id_for_tag
export def "tags-relationships-tag-group tag" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tags/($id)/relationships/tag-group")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tags for Tag Group
#
# GET /api/tag-groups/{id}/tags
# operationId: get_tags_for_tag_group
export def "tag-groups-tags group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstag: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tag]" $fieldstag "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tag-groups/($id)/tags" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tag IDs for Tag Group
#
# GET /api/tag-groups/{id}/relationships/tags
# operationId: get_tag_ids_for_tag_group
export def "tag-groups-relationships-tags group" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/tag-groups/($id)/relationships/tags")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Templates
#
# GET /api/templates
# operationId: get_templates
export def "templates templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldstemplate: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`, `equals`<br>`name`: `any`, `contains`, `equals`<br>`created`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `equals`, `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(id,['example']))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 10. Min: 1. Max: 10. (default: 10)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[template]" $additional_fieldstemplate "csv") (serialize-qp "fields[template]" $fieldstemplate "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Template
#
# POST /api/templates
# operationId: create_template
export def "templates template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldstemplate: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[template]" $additional_fieldstemplate "csv") (serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/templates" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Template
#
# GET /api/templates/{id}
# operationId: get_template
export def "templates template-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldstemplate: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[template]" $additional_fieldstemplate "csv") (serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/templates/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Template
#
# PATCH /api/templates/{id}
# operationId: update_template
export def "templates template-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-fieldstemplate: list # Request additional fields not included by default in the response. Supported values: 'definition'
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "additional-fields[template]" $additional_fieldstemplate "csv") (serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/templates/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Template
#
# DELETE /api/templates/{id}
# operationId: delete_template
export def "templates template-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/templates/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Universal Content
#
# GET /api/template-universal-content
# operationId: get_all_universal_content
export def "template-universal-content content" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate-universal-content: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`id`: `any`, `equals`<br>`name`: `any`, `equals`<br>`created`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`definition.content_type`: `equals`<br>`definition.type`: `equals` (e.g. equals(id,'01HWWWKAW4RHXQJCMW4R2KRYR4'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-5 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template-universal-content]" $fieldstemplate_universal_content "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/template-universal-content" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Universal Content
#
# POST /api/template-universal-content
# operationId: create_universal_content
export def "template-universal-content content-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate-universal-content: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template-universal-content]" $fieldstemplate_universal_content "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/template-universal-content" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Universal Content
#
# GET /api/template-universal-content/{id}
# operationId: get_universal_content
export def "template-universal-content content-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate-universal-content: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template-universal-content]" $fieldstemplate_universal_content "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/template-universal-content/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Universal Content
#
# PATCH /api/template-universal-content/{id}
# operationId: update_universal_content
export def "template-universal-content content-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate-universal-content: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template-universal-content]" $fieldstemplate_universal_content "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/template-universal-content/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Universal Content
#
# DELETE /api/template-universal-content/{id}
# operationId: delete_universal_content
export def "template-universal-content content-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/template-universal-content/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Render Template
#
# POST /api/template-render
# operationId: render_template
export def "template-render template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/template-render" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Clone Template
#
# POST /api/template-clone
# operationId: clone_template
export def "template-clone template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstemplate: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[template]" $fieldstemplate "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/template-clone" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Tracking Settings
#
# GET /api/tracking-settings
# operationId: get_tracking_settings
export def "tracking-settings settings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstracking-setting: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 1. Min: 1. Max: 1. (default: 1)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tracking-setting]" $fieldstracking_setting "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/tracking-settings" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Tracking Setting
#
# GET /api/tracking-settings/{id}
# operationId: get_tracking_setting
export def "tracking-settings setting-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstracking-setting: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tracking-setting]" $fieldstracking_setting "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tracking-settings/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Tracking Setting
#
# PATCH /api/tracking-settings/{id}
# operationId: update_tracking_setting
export def "tracking-settings setting-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldstracking-setting: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[tracking-setting]" $fieldstracking_setting "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/tracking-settings/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Web Feeds
#
# GET /api/web-feeds
# operationId: get_web_feeds
export def "web-feeds feeds" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsweb-feed: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`name`: `any`, `contains`, `equals`<br>`created`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than`<br>`updated`: `greater-or-equal`, `greater-than`, `less-or-equal`, `less-than` (e.g. equals(name,'Blog_posts'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 5. Min: 1. Max: 20. (default: 5)
  --qp-sort: string@sort-completer-13 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[web-feed]" $fieldsweb_feed "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/web-feeds" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Web Feed
#
# POST /api/web-feeds
# operationId: create_web_feed
export def "web-feeds feed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsweb-feed: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[web-feed]" $fieldsweb_feed "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/web-feeds" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Web Feed
#
# GET /api/web-feeds/{id}
# operationId: get_web_feed
export def "web-feeds feed-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsweb-feed: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[web-feed]" $fieldsweb_feed "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/web-feeds/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Web Feed
#
# PATCH /api/web-feeds/{id}
# operationId: update_web_feed
export def "web-feeds feed-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldsweb-feed: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[web-feed]" $fieldsweb_feed "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/web-feeds/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Web Feed
#
# DELETE /api/web-feeds/{id}
# operationId: delete_web_feed
export def "web-feeds feed-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/web-feeds/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhooks
#
# GET /api/webhooks
# operationId: get_webhooks
export def "webhooks webhooks" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook-topic: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldswebhook: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook-topic]" $fieldswebhook_topic "csv") (serialize-qp "fields[webhook]" $fieldswebhook "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webhooks" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Webhook
#
# POST /api/webhooks
# operationId: create_webhook
export def "webhooks webhook" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook]" $fieldswebhook "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webhooks" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Webhook
#
# GET /api/webhooks/{id}
# operationId: get_webhook
export def "webhooks webhook-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook-topic: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --fieldswebhook: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --include: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#relationships
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook-topic]" $fieldswebhook_topic "csv") (serialize-qp "fields[webhook]" $fieldswebhook "csv") (serialize-qp "include" $include "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/webhooks/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Webhook
#
# PATCH /api/webhooks/{id}
# operationId: update_webhook
export def "webhooks webhook-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook]" $fieldswebhook "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/webhooks/($id)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Delete Webhook
#
# DELETE /api/webhooks/{id}
# operationId: delete_webhook
export def "webhooks webhook-by-id-2" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/api/webhooks/($id)")
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhook Topics
#
# GET /api/webhook-topics
# operationId: get_webhook_topics
export def "webhook-topics topics" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook-topic: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook-topic]" $fieldswebhook_topic "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/api/webhook-topics" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Webhook Topic
#
# GET /api/webhook-topics/{id}
# operationId: get_webhook_topic
export def "webhook-topics topic" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --fieldswebhook-topic: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields[webhook-topic]" $fieldswebhook_topic "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/api/webhook-topics/($id)" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Client Review Values Reports
#
# GET /client/review-values-reports
# operationId: get_client_review_values_reports
export def "client-review-values-reports reports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --fieldsreview-values-report: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`product_external_ids`: `any`, `equals` (e.g. equals(product_external_ids,'example'))
  --group-by: string@group-by-completer # group by value for this report (e.g. product_id)
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --statistics: string # list of statistics to calculate for this report (e.g. average_rating,total_reviews)
  --timeframe: string@timeframe-completer # timeframe window for value report (e.g. all_time)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar") (serialize-qp "fields[review-values-report]" $fieldsreview_values_report "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "group_by" $group_by "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "statistics" $statistics "scalar") (serialize-qp "timeframe" $timeframe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/review-values-reports" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Client Reviews
#
# GET /client/reviews
# operationId: get_client_reviews
export def "client-reviews reviews" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --fieldsreview: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --filter: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#filtering<br>Allowed field(s)/operator(s):<br>`status`: `equals`<br>`review_type`: `equals`<br>`rating`: `any`, `equals`, `greater-or-equal`, `less-or-equal`<br>`id`: `any`, `equals`<br>`content`: `contains`<br>`smart_quote`: `has`<br>`public_reply`: `has`<br>`verified`: `equals`<br>`incentivized`: `equals`<br>`edited`: `equals`<br>`media`: `has`<br>`created`: `greater-or-equal`, `less-or-equal`<br>`updated`: `greater-or-equal`, `less-or-equal` (e.g. equals(status,'published'))
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --qp-sort: string@sort-completer-11 # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sorting
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar") (serialize-qp "fields[review]" $fieldsreview "csv") (serialize-qp "filter" $filter "scalar") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/reviews" $qp)
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Client Review
#
# POST /client/reviews
# operationId: create_client_review
export def "client-reviews review" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/reviews" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Get Client Geofences
#
# GET /client/geofences
# operationId: get_client_geofences
export def "client-geofences geofences" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --fieldsgeofence: list # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#sparse-fieldsets
  --pagecursor: string # For more information please visit https://developers.klaviyo.com/en/v2026-04-15/reference/api-overview#pagination
  --pagesize: int # Default: 20. Min: 1. Max: 100. (default: 20)
  --X-Klaviyo-API-Filters: string #  Supported filters: - `lat` (equals) - Latitude coordinate for distance-based sorting - `lng` (equals) - Longitude coordinate for distance-based sorting  When both lat and lng are provided, geofences are returned sorted by distance from the specified coordinates (closest first).  (e.g. and(equals(lat,40.7128),equals(lng,-74.0060)))
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar") (serialize-qp "fields[geofence]" $fieldsgeofence "csv") (serialize-qp "page[cursor]" $pagecursor "scalar") (serialize-qp "page[size]" $pagesize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/geofences" $qp)
  let extra_headers = {"X-Klaviyo-API-Filters": $X_Klaviyo_API_Filters, "revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/vnd.api+json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Client Subscription
#
# POST /client/subscriptions
# operationId: create_client_subscription
export def "client-subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/subscriptions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create or Update Client Push Token
#
# POST /client/push-tokens
# operationId: create_client_push_token
export def "client-push-tokens token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/push-tokens" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Unregister Client Push Token
#
# POST /client/push-token-unregister
# operationId: unregister_client_push_token
export def "client-push-token-unregister token" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/push-token-unregister" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create Client Event
#
# POST /client/events
# operationId: create_client_event
export def "client-events event" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/events" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create or Update Client Profile
#
# POST /client/profiles
# operationId: create_client_profile
export def "client-profiles profile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/profiles" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Bulk Create Client Events
#
# POST /client/event-bulk-create
# operationId: bulk_create_client_events
export def "client-event-bulk-create events" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/event-bulk-create" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}

# Create Client Back In Stock Subscription
#
# POST /client/back-in-stock-subscriptions
# operationId: create_client_back_in_stock_subscription
export def "client-back-in-stock-subscriptions subscription" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --company-id: string # Your Public API Key / Site ID. See [this article](https://help.klaviyo.com/hc/en-us/articles/115005062267) for more details. (e.g. PUBLIC_API_KEY)
  --revision: string # API endpoint revision (format: YYYY-MM-DD[.suffix])
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "company_id" $company_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/client/back-in-stock-subscriptions" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"revision": $revision} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/vnd.api+json" $body
}
