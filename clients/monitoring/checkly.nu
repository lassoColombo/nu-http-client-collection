# Auto-generated client for Checkly Public API vv1
# Source: https://api.checklyhq.com/openapi.json
# Auth: --token flag or $env.CHECKLY_PUBLIC_API_TOKEN

const BASE_URL = "https://api.checklyhq.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CHECKLY_PUBLIC_API_TOKEN | default "" }
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
def base-url-completer [] { ["https://api.checklyhq.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def type-completer [] { ["invite" "member"] }
def role-completer [] { ["ADMIN" "OWNER" "READ_ONLY" "READ_RUN" "READ_WRITE"] }
def status-completer [] { ["ACTIVE" "EXPIRED" "PENDING"] }
def role-completer-1 [] { ["ADMIN" "READ_ONLY" "READ_RUN" "READ_WRITE"] }
def type-completer-1 [] { ["CALL" "EMAIL" "OPSGENIE" "PAGERDUTY" "SLACK" "SLACK_APP" "SMS" "WEBHOOK"] }
def quickRange-completer [] { ["last24Hours" "last30Days" "last7Days" "lastMonth" "lastWeek" "thisMonth" "thisWeek"] }
def groupBy-completer [] { ["runLocation" "statusCode"] }
def groupBy-completer-1 [] { ["pageIndex" "runLocation"] }
def quickRange-completer-1 [] { ["last24Hours" "last7Days" "lastMonth" "lastWeek" "thisWeek"] }
def groupBy-completer-2 [] { ["runLocation"] }
def checkType-completer [] { ["AGENTIC" "API" "BROWSER" "DNS" "HEARTBEAT" "ICMP" "MULTI_STEP" "PLAYWRIGHT" "TCP" "TRACEROUTE" "URL"] }
def style-completer [] { ["flat" "flat-square" "for-the-badge" "plastic" "social"] }
def theme-completer [] { ["dark" "default" "light"] }
def runtimeId-completer [] { ["2022.10" "2023.02" "2023.09" "2024.02" "2024.09" "2025.04" "2026.04"] }
def location-completer [] { ["af-south-1" "ap-east-1" "ap-northeast-1" "ap-northeast-2" "ap-northeast-3" "ap-south-1" "ap-southeast-1" "ap-southeast-2" "ap-southeast-3" "ca-central-1" "eu-central-1" "eu-north-1" "eu-south-1" "eu-west-1" "eu-west-2" "eu-west-3" "me-south-1" "sa-east-1" "us-east-1" "us-east-2" "us-west-1" "us-west-2"] }
def resultType-completer [] { ["ALL" "ATTEMPT" "FINAL"] }
def status-completer-1 [] { ["degraded" "failing" "passing"] }
def frequency-completer [] { ["0" "1" "10" "120" "1440" "15" "180" "2" "30" "360" "5" "60" "720"] }
def frequency-completer-1 [] { ["1" "10" "120" "1440" "15" "180" "2" "30" "360" "5" "60" "720"] }
def checkType-completer-1 [] { ["DNS"] }
def checkType-completer-2 [] { ["MULTI_STEP"] }
def width-completer [] { ["960PX" "FULL"] }
def refreshRate-completer [] { ["300" "60" "600"] }
def paginationRate-completer [] { ["30" "300" "60"] }
def type-completer-2 [] { ["customDomain" "customUrl"] }
def impact-completer [] { ["MAINTENANCE" "MAJOR" "MINOR"] }
def status-completer-2 [] { ["IDENTIFIED" "INVESTIGATING" "MAINTENANCE" "MONITORING" "RESOLVED"] }
def repeatUnit-completer [] { ["DAY" "MONTH" "WEEK"] }
def status-completer-3 [] { ["CANCELLED" "COMPLETED" "IN_PROGRESS" "SCHEDULED" "VERIFYING"] }
def quickRange-completer-2 [] { ["last24Hrs" "last30Days" "last7Days" "lastMonth" "lastWeek" "thisMonth" "thisWeek"] }
def defaultTheme-completer [] { ["AUTO" "DARK" "LIGHT"] }
def lastUpdateStatus-completer [] { ["IDENTIFIED" "INVESTIGATING" "MONITORING" "RESOLVED"] }
def severity-completer [] { ["CRITICAL" "MAJOR" "MEDIUM" "MINOR"] }
def status-completer-4 [] { ["IDENTIFIED" "INVESTIGATING" "MONITORING" "RESOLVED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts list" } } | get name | first)
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

# Fetch user accounts
#
# GET /v1/accounts
# operationId: getV1Accounts
export def "accounts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, name: string, runtimeId: string, plan: string, planDisplayName: string, addons: record<communicate: record, resolve: record>, settings: record, alertSettings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch current account details
#
# GET /v1/accounts/me
# operationId: getV1AccountsMe
export def "accounts-me get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, name: string, runtimeId: string, plan: string, planDisplayName: string, addons: record<communicate: record<tier: string, tierDisplayName: string>, resolve: record<tier: string, tierDisplayName: string>>, settings: record, alertSettings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts/me")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch current account entitlements
#
# GET /v1/accounts/me/entitlements
# operationId: getV1AccountsMeEntitlements
export def "accounts-me-entitlements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<plan: string, planDisplayName: string, addons: record<communicate: record<tier: string, tierDisplayName: string>, resolve: record<tier: string, tierDisplayName: string>>, locations: record<all: list<record>, maxPerCheck: int>, entitlements: table<key: string, name: string, description: string, type: string, enabled: bool, quantity: int, requiredPlan: string, requiredPlanDisplayName: string, requiredAddon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/accounts/me/entitlements")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List current account members and pending invites
#
# GET /v1/accounts/me/members
# operationId: getV1AccountsMeMembers
export def "accounts-me-members get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Case-insensitive partial match against member name, member email, and invite email. Empty searches are ignored.
  --type: string@type-completer # Filter by account member list item type.
  --role: string@role-completer # Filter by account role. Valid filters may produce no results for invites.
  --status: string@status-completer # Filter by member or invite status. Valid filters may produce no results for some item types.
  --limit: int # Page length. Omitted returns all matching members and invites.
  --nextId: string # Opaque cursor returned from a previous limited request. Only accepted with limit and the same query params.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<members: list<any>, length: int, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/accounts/me/members" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove a current account member
#
# DELETE /v1/accounts/me/members/{userId}
# operationId: deleteV1AccountsMeMembersUserid
export def "accounts-me-members delete" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/me/members/($userId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a current account member role
#
# PATCH /v1/accounts/me/members/{userId}
# operationId: patchV1AccountsMeMembersUserid
export def "accounts-me-members patch" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  role: string@role-completer-1 # New account member role. OWNER is not supported.
]: any -> record<type: string, accountId: string, userId: string, name: string, email: string, role: string, status: string, createdAt: string, updatedAt: string, isSupportMembership: bool, ssoEnabled: bool, mfaEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/me/members/($userId)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Fetch a given account details
#
# GET /v1/accounts/{accountId}
# operationId: getV1AccountsAccountid
export def "accounts get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, name: string, runtimeId: string, plan: string, planDisplayName: string, addons: record<communicate: record<tier: string, tierDisplayName: string>, resolve: record<tier: string, tierDisplayName: string>>, settings: record, alertSettings: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Fetch account entitlements
#
# GET /v1/accounts/{accountId}/entitlements
# operationId: getV1AccountsAccountidEntitlements
export def "accounts-entitlements get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<plan: string, planDisplayName: string, addons: record<communicate: record<tier: string, tierDisplayName: string>, resolve: record<tier: string, tierDisplayName: string>>, locations: record<all: list<record>, maxPerCheck: int>, entitlements: table<key: string, name: string, description: string, type: string, enabled: bool, quantity: int, requiredPlan: string, requiredPlanDisplayName: string, requiredAddon: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/entitlements")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List account members and pending invites
#
# GET /v1/accounts/{accountId}/members
# operationId: getV1AccountsAccountidMembers
export def "accounts-members get" [
  accountId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --search: string # Case-insensitive partial match against member name, member email, and invite email. Empty searches are ignored.
  --type: string@type-completer # Filter by account member list item type.
  --role: string@role-completer # Filter by account role. Valid filters may produce no results for invites.
  --status: string@status-completer # Filter by member or invite status. Valid filters may produce no results for some item types.
  --limit: int # Page length. Omitted returns all matching members and invites.
  --nextId: string # Opaque cursor returned from a previous limited request. Only accepted with limit and the same query params.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<members: list<any>, length: int, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "search" $search "scalar") (serialize-qp "type" $type "scalar") (serialize-qp "role" $role "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/accounts/($accountId)/members" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an account member
#
# DELETE /v1/accounts/{accountId}/members/{userId}
# operationId: deleteV1AccountsAccountidMembersUserid
export def "accounts-members delete" [
  accountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/members/($userId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an account member role
#
# PATCH /v1/accounts/{accountId}/members/{userId}
# operationId: patchV1AccountsAccountidMembersUserid
export def "accounts-members patch" [
  accountId: string
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  role: string@role-completer-1 # New account member role. OWNER is not supported.
]: any -> record<type: string, accountId: string, userId: string, name: string, email: string, role: string, status: string, createdAt: string, updatedAt: string, isSupportMembership: bool, ssoEnabled: bool, mfaEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/accounts/($accountId)/members/($userId)")
  let body = {role: $role} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all alert channels
#
# GET /v1/alert-channels
# operationId: getV1Alertchannels
export def "alert-channels list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: float, type: string, config: record, subscriptions: list<record>, sendRecovery: bool, sendFailure: bool, sendDegraded: bool, sslExpiry: bool, sslExpiryThreshold: int, autoSubscribe: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/alert-channels" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an alert channel
#
# POST /v1/alert-channels
# operationId: postV1Alertchannels
# --subscriptions item shape: {id?: float, checkId?: string, groupId?: float, activated: bool}
export def "alert-channels post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --subscriptions: list # All checks subscribed to this channel. (e.g. []) — item shape: {id?: float, checkId?: string, groupId?: float, activated: bool}
  type: string@type-completer-1 # e.g. SMS
  config: record
  --sendRecovery: string@bool-completer
  --sendFailure: string@bool-completer
  --sendDegraded: string@bool-completer
  --sslExpiry: string@bool-completer # Determines if an alert should be sent for expiring SSL certificates. (default: false)
  --sslExpiryThreshold: int # At what moment in time to start alerting on SSL certificates. (default: 30)
  --autoSubscribe: string@bool-completer # Automatically subscribe newly created checks to this alert channel. (default: false)
]: any -> record<id: float, type: string, config: record, subscriptions: table<id: float, checkId: string, groupId: float, activated: bool>, sendRecovery: bool, sendFailure: bool, sendDegraded: bool, sslExpiry: bool, sslExpiryThreshold: int, autoSubscribe: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/alert-channels")
  let body = {subscriptions: $subscriptions, type: $type, config: $config, sendRecovery: $sendRecovery, sendFailure: $sendFailure, sendDegraded: $sendDegraded, sslExpiry: $sslExpiry, sslExpiryThreshold: $sslExpiryThreshold, autoSubscribe: $autoSubscribe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an alert channel
#
# DELETE /v1/alert-channels/{id}
# operationId: deleteV1AlertchannelsId
export def "alert-channels delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-channels/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an alert channel
#
# GET /v1/alert-channels/{id}
# operationId: getV1AlertchannelsId
export def "alert-channels get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, type: string, config: record, subscriptions: table<id: float, checkId: string, groupId: float, activated: bool>, sendRecovery: bool, sendFailure: bool, sendDegraded: bool, sslExpiry: bool, sslExpiryThreshold: int, autoSubscribe: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-channels/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an alert channel
#
# PUT /v1/alert-channels/{id}
# operationId: putV1AlertchannelsId
# --subscriptions item shape: {id?: float, checkId?: string, groupId?: float, activated: bool}
export def "alert-channels put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --subscriptions: list # All checks subscribed to this channel. (e.g. []) — item shape: {id?: float, checkId?: string, groupId?: float, activated: bool}
  type: string@type-completer-1 # e.g. SMS
  config: record
  --sendRecovery: string@bool-completer
  --sendFailure: string@bool-completer
  --sendDegraded: string@bool-completer
  --sslExpiry: string@bool-completer # Determines if an alert should be sent for expiring SSL certificates. (default: false)
  --sslExpiryThreshold: int # At what moment in time to start alerting on SSL certificates. (default: 30)
  --autoSubscribe: string@bool-completer # Automatically subscribe newly created checks to this alert channel. (default: false)
]: any -> record<id: float, type: string, config: record, subscriptions: table<id: float, checkId: string, groupId: float, activated: bool>, sendRecovery: bool, sendFailure: bool, sendDegraded: bool, sslExpiry: bool, sslExpiryThreshold: int, autoSubscribe: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-channels/($id)")
  let body = {subscriptions: $subscriptions, type: $type, config: $config, sendRecovery: $sendRecovery, sendFailure: $sendFailure, sendDegraded: $sendDegraded, sslExpiry: $sslExpiry, sslExpiryThreshold: $sslExpiryThreshold, autoSubscribe: $autoSubscribe} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update the subscriptions of an alert channel
#
# PUT /v1/alert-channels/{id}/subscriptions
# operationId: putV1AlertchannelsIdSubscriptions
export def "alert-channels-subscriptions put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --checkId: string # You can either pass a checkId or a groupId, but not both. (nullable, e.g. 0bbfc00c-44df-46a7-a4d9-ba38deca8bfd)
  --groupId: float # You can either pass a checkId or a groupId, but not both. (nullable)
  --activated: string@bool-completer
]: any -> record<id: float, checkId: string, groupId: float, activated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/alert-channels/($id)/subscriptions")
  let body = {checkId: $checkId, groupId: $groupId, activated: $activated} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all alert notifications
#
# GET /v1/alert-notifications
# operationId: getV1Alertnotifications
export def "alert-notifications get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --qp-from: string # Select records up from this UNIX timestamp (>= date). Defaults to now - 6 hours. (format: date)
  --qp-to: string # Optional. Select records up to this UNIX timestamp (< date). Defaults to 6 hours after "from". (format: date)
  --alertChannelId: int # Limit results to an alert channel
  --hasFailures: string@bool-completer # Sending the alert notification was unsuccessful
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, type: string, status: string, alertConfig: record, notificationResult: string, timestamp: string, checkType: string, checkId: string, checkAlertId: string, alertChannelId: float, checkResultId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "alertChannelId" $alertChannelId "scalar") (serialize-qp "hasFailures" $hasFailures "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/alert-notifications" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# API checks
#
# GET /v1/analytics/api-checks/{id}
# operationId: getV1AnalyticsApichecksId
export def "analytics-api-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for API Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<responseTime: record<unit: string, label: string, aggregation: string>, wait: record<unit: string, label: string, aggregation: string>, dns: record<unit: string, label: string, aggregation: string>, tcp: record<unit: string, label: string, aggregation: string>, firstByte: record<unit: string, label: string, aggregation: string>, download: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, responseTime_avg: record<unit: string, label: string, aggregation: string>, responseTime_max: record<unit: string, label: string, aggregation: string>, responseTime_median: record<unit: string, label: string, aggregation: string>, responseTime_min: record<unit: string, label: string, aggregation: string>, responseTime_p50: record<unit: string, label: string, aggregation: string>, responseTime_p90: record<unit: string, label: string, aggregation: string>, responseTime_p95: record<unit: string, label: string, aggregation: string>, responseTime_p99: record<unit: string, label: string, aggregation: string>, responseTime_stddev: record<unit: string, label: string, aggregation: string>, responseTime_sum: record<unit: string, label: string, aggregation: string>, wait_avg: record<unit: string, label: string, aggregation: string>, wait_max: record<unit: string, label: string, aggregation: string>, wait_median: record<unit: string, label: string, aggregation: string>, wait_min: record<unit: string, label: string, aggregation: string>, wait_p50: record<unit: string, label: string, aggregation: string>, wait_p90: record<unit: string, label: string, aggregation: string>, wait_p95: record<unit: string, label: string, aggregation: string>, wait_p99: record<unit: string, label: string, aggregation: string>, wait_stddev: record<unit: string, label: string, aggregation: string>, wait_sum: record<unit: string, label: string, aggregation: string>, dns_avg: record<unit: string, label: string, aggregation: string>, dns_max: record<unit: string, label: string, aggregation: string>, dns_median: record<unit: string, label: string, aggregation: string>, dns_min: record<unit: string, label: string, aggregation: string>, dns_p50: record<unit: string, label: string, aggregation: string>, dns_p90: record<unit: string, label: string, aggregation: string>, dns_p95: record<unit: string, label: string, aggregation: string>, dns_p99: record<unit: string, label: string, aggregation: string>, dns_stddev: record<unit: string, label: string, aggregation: string>, dns_sum: record<unit: string, label: string, aggregation: string>, tcp_avg: record<unit: string, label: string, aggregation: string>, tcp_max: record<unit: string, label: string, aggregation: string>, tcp_median: record<unit: string, label: string, aggregation: string>, tcp_min: record<unit: string, label: string, aggregation: string>, tcp_p50: record<unit: string, label: string, aggregation: string>, tcp_p90: record<unit: string, label: string, aggregation: string>, tcp_p95: record<unit: string, label: string, aggregation: string>, tcp_p99: record<unit: string, label: string, aggregation: string>, tcp_stddev: record<unit: string, label: string, aggregation: string>, tcp_sum: record<unit: string, label: string, aggregation: string>, firstByte_avg: record<unit: string, label: string, aggregation: string>, firstByte_max: record<unit: string, label: string, aggregation: string>, firstByte_median: record<unit: string, label: string, aggregation: string>, firstByte_min: record<unit: string, label: string, aggregation: string>, firstByte_p50: record<unit: string, label: string, aggregation: string>, firstByte_p90: record<unit: string, label: string, aggregation: string>, firstByte_p95: record<unit: string, label: string, aggregation: string>, firstByte_p99: record<unit: string, label: string, aggregation: string>, firstByte_stddev: record<unit: string, label: string, aggregation: string>, firstByte_sum: record<unit: string, label: string, aggregation: string>, download_avg: record<unit: string, label: string, aggregation: string>, download_max: record<unit: string, label: string, aggregation: string>, download_median: record<unit: string, label: string, aggregation: string>, download_min: record<unit: string, label: string, aggregation: string>, download_p50: record<unit: string, label: string, aggregation: string>, download_p90: record<unit: string, label: string, aggregation: string>, download_p95: record<unit: string, label: string, aggregation: string>, download_p99: record<unit: string, label: string, aggregation: string>, download_stddev: record<unit: string, label: string, aggregation: string>, download_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/api-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Browser checks
#
# GET /v1/analytics/browser-checks/{id}
# operationId: getV1AnalyticsBrowserchecksId
export def "analytics-browser-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-1 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for Browser Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<responseTime: record<unit: string, label: string, aggregation: string>, TTFB: record<unit: string, label: string, aggregation: string>, FCP: record<unit: string, label: string, aggregation: string>, LCP: record<unit: string, label: string, aggregation: string>, CLS: record<unit: string, label: string, aggregation: string>, TBT: record<unit: string, label: string, aggregation: string>, consoleErrors: record<unit: string, label: string, aggregation: string>, networkErrors: record<unit: string, label: string, aggregation: string>, userScriptErrors: record<unit: string, label: string, aggregation: string>, documentErrors: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, responseTime_avg: record<unit: string, label: string, aggregation: string>, responseTime_max: record<unit: string, label: string, aggregation: string>, responseTime_median: record<unit: string, label: string, aggregation: string>, responseTime_min: record<unit: string, label: string, aggregation: string>, responseTime_p50: record<unit: string, label: string, aggregation: string>, responseTime_p90: record<unit: string, label: string, aggregation: string>, responseTime_p95: record<unit: string, label: string, aggregation: string>, responseTime_p99: record<unit: string, label: string, aggregation: string>, responseTime_stddev: record<unit: string, label: string, aggregation: string>, responseTime_sum: record<unit: string, label: string, aggregation: string>, TTFB_avg: record<unit: string, label: string, aggregation: string>, TTFB_max: record<unit: string, label: string, aggregation: string>, TTFB_median: record<unit: string, label: string, aggregation: string>, TTFB_min: record<unit: string, label: string, aggregation: string>, TTFB_p50: record<unit: string, label: string, aggregation: string>, TTFB_p90: record<unit: string, label: string, aggregation: string>, TTFB_p95: record<unit: string, label: string, aggregation: string>, TTFB_p99: record<unit: string, label: string, aggregation: string>, TTFB_stddev: record<unit: string, label: string, aggregation: string>, TTFB_sum: record<unit: string, label: string, aggregation: string>, FCP_avg: record<unit: string, label: string, aggregation: string>, FCP_max: record<unit: string, label: string, aggregation: string>, FCP_median: record<unit: string, label: string, aggregation: string>, FCP_min: record<unit: string, label: string, aggregation: string>, FCP_p50: record<unit: string, label: string, aggregation: string>, FCP_p90: record<unit: string, label: string, aggregation: string>, FCP_p95: record<unit: string, label: string, aggregation: string>, FCP_p99: record<unit: string, label: string, aggregation: string>, FCP_stddev: record<unit: string, label: string, aggregation: string>, FCP_sum: record<unit: string, label: string, aggregation: string>, LCP_avg: record<unit: string, label: string, aggregation: string>, LCP_max: record<unit: string, label: string, aggregation: string>, LCP_median: record<unit: string, label: string, aggregation: string>, LCP_min: record<unit: string, label: string, aggregation: string>, LCP_p50: record<unit: string, label: string, aggregation: string>, LCP_p90: record<unit: string, label: string, aggregation: string>, LCP_p95: record<unit: string, label: string, aggregation: string>, LCP_p99: record<unit: string, label: string, aggregation: string>, LCP_stddev: record<unit: string, label: string, aggregation: string>, LCP_sum: record<unit: string, label: string, aggregation: string>, CLS_avg: record<unit: string, label: string, aggregation: string>, CLS_max: record<unit: string, label: string, aggregation: string>, CLS_median: record<unit: string, label: string, aggregation: string>, CLS_min: record<unit: string, label: string, aggregation: string>, CLS_p50: record<unit: string, label: string, aggregation: string>, CLS_p90: record<unit: string, label: string, aggregation: string>, CLS_p95: record<unit: string, label: string, aggregation: string>, CLS_p99: record<unit: string, label: string, aggregation: string>, CLS_stddev: record<unit: string, label: string, aggregation: string>, CLS_sum: record<unit: string, label: string, aggregation: string>, TBT_avg: record<unit: string, label: string, aggregation: string>, TBT_max: record<unit: string, label: string, aggregation: string>, TBT_median: record<unit: string, label: string, aggregation: string>, TBT_min: record<unit: string, label: string, aggregation: string>, TBT_p50: record<unit: string, label: string, aggregation: string>, TBT_p90: record<unit: string, label: string, aggregation: string>, TBT_p95: record<unit: string, label: string, aggregation: string>, TBT_p99: record<unit: string, label: string, aggregation: string>, TBT_stddev: record<unit: string, label: string, aggregation: string>, TBT_sum: record<unit: string, label: string, aggregation: string>, consoleErrors_avg: record<unit: string, label: string, aggregation: string>, consoleErrors_max: record<unit: string, label: string, aggregation: string>, consoleErrors_median: record<unit: string, label: string, aggregation: string>, consoleErrors_min: record<unit: string, label: string, aggregation: string>, consoleErrors_p50: record<unit: string, label: string, aggregation: string>, consoleErrors_p90: record<unit: string, label: string, aggregation: string>, consoleErrors_p95: record<unit: string, label: string, aggregation: string>, consoleErrors_p99: record<unit: string, label: string, aggregation: string>, consoleErrors_stddev: record<unit: string, label: string, aggregation: string>, consoleErrors_sum: record<unit: string, label: string, aggregation: string>, networkErrors_avg: record<unit: string, label: string, aggregation: string>, networkErrors_max: record<unit: string, label: string, aggregation: string>, networkErrors_median: record<unit: string, label: string, aggregation: string>, networkErrors_min: record<unit: string, label: string, aggregation: string>, networkErrors_p50: record<unit: string, label: string, aggregation: string>, networkErrors_p90: record<unit: string, label: string, aggregation: string>, networkErrors_p95: record<unit: string, label: string, aggregation: string>, networkErrors_p99: record<unit: string, label: string, aggregation: string>, networkErrors_stddev: record<unit: string, label: string, aggregation: string>, networkErrors_sum: record<unit: string, label: string, aggregation: string>, userScriptErrors_avg: record<unit: string, label: string, aggregation: string>, userScriptErrors_max: record<unit: string, label: string, aggregation: string>, userScriptErrors_median: record<unit: string, label: string, aggregation: string>, userScriptErrors_min: record<unit: string, label: string, aggregation: string>, userScriptErrors_p50: record<unit: string, label: string, aggregation: string>, userScriptErrors_p90: record<unit: string, label: string, aggregation: string>, userScriptErrors_p95: record<unit: string, label: string, aggregation: string>, userScriptErrors_p99: record<unit: string, label: string, aggregation: string>, userScriptErrors_stddev: record<unit: string, label: string, aggregation: string>, userScriptErrors_sum: record<unit: string, label: string, aggregation: string>, documentErrors_avg: record<unit: string, label: string, aggregation: string>, documentErrors_max: record<unit: string, label: string, aggregation: string>, documentErrors_median: record<unit: string, label: string, aggregation: string>, documentErrors_min: record<unit: string, label: string, aggregation: string>, documentErrors_p50: record<unit: string, label: string, aggregation: string>, documentErrors_p90: record<unit: string, label: string, aggregation: string>, documentErrors_p95: record<unit: string, label: string, aggregation: string>, documentErrors_p99: record<unit: string, label: string, aggregation: string>, documentErrors_stddev: record<unit: string, label: string, aggregation: string>, documentErrors_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/browser-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get analytics summary for multiple checks
#
# POST /v1/analytics/checks
# operationId: postV1AnalyticsChecks
export def "analytics-checks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --quickRange: string@quickRange-completer-1 # Time range for analytics. (default: last24Hours)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  checkIds: list # Array of check IDs to fetch analytics for.
]: any -> table<checkId: string, checkType: string, availability: float, responseTime_avg: float, responseTime_p50: float, responseTime_p95: float, responseTime_p99: float, latency_avg: float, latency_p50: float, latency_p95: float, latency_p99: float, packetLoss_avg: float, packetLoss_p95: float, packetLoss_p99: float> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "quickRange" $quickRange "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/analytics/checks" $qp)
  let body = {checkIds: $checkIds} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# DNS monitors
#
# GET /v1/analytics/dns/{id}
# operationId: getV1AnalyticsDnsId
export def "analytics-dns get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-2 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for DNS Monitors. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<total: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, total_avg: record<unit: string, label: string, aggregation: string>, total_max: record<unit: string, label: string, aggregation: string>, total_median: record<unit: string, label: string, aggregation: string>, total_min: record<unit: string, label: string, aggregation: string>, total_p50: record<unit: string, label: string, aggregation: string>, total_p90: record<unit: string, label: string, aggregation: string>, total_p95: record<unit: string, label: string, aggregation: string>, total_p99: record<unit: string, label: string, aggregation: string>, total_stddev: record<unit: string, label: string, aggregation: string>, total_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/dns/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Heartbeat checks
#
# GET /v1/analytics/heartbeat-checks/{id}
# operationId: getV1AnalyticsHeartbeatchecksId
export def "analytics-heartbeat-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --filterByStatus: list # Filter based on whether a heartbeat request was late, early, etc. (e.g. [FAILING])
  --metrics: list # Available metrics for Heartbeat Checks. You can pass multiple metrics as a comma separated string. (default: [availability])
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/heartbeat-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# ICMP monitors
#
# GET /v1/analytics/icmp/{id}
# operationId: getV1AnalyticsIcmpId
export def "analytics-icmp get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-2 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for ICMP Monitors. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<string: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/icmp/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all available reporting metrics.
#
# GET /v1/analytics/metrics
# operationId: getV1AnalyticsMetrics
export def "analytics-metrics get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --checkType: string@checkType-completer
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> list<string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkType" $checkType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/analytics/metrics" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Multistep checks
#
# GET /v1/analytics/multistep-checks/{id}
# operationId: getV1AnalyticsMultistepchecksId
export def "analytics-multistep-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-2 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for Multistep Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<responseTime: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, responseTime_avg: record<unit: string, label: string, aggregation: string>, responseTime_max: record<unit: string, label: string, aggregation: string>, responseTime_median: record<unit: string, label: string, aggregation: string>, responseTime_min: record<unit: string, label: string, aggregation: string>, responseTime_p50: record<unit: string, label: string, aggregation: string>, responseTime_p90: record<unit: string, label: string, aggregation: string>, responseTime_p95: record<unit: string, label: string, aggregation: string>, responseTime_p99: record<unit: string, label: string, aggregation: string>, responseTime_stddev: record<unit: string, label: string, aggregation: string>, responseTime_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/multistep-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Playwright checks
#
# GET /v1/analytics/playwright-checks/{id}
# operationId: getV1AnalyticsPlaywrightchecksId
export def "analytics-playwright-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-2 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for Playwright Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<responseTime: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, responseTime_avg: record<unit: string, label: string, aggregation: string>, responseTime_max: record<unit: string, label: string, aggregation: string>, responseTime_median: record<unit: string, label: string, aggregation: string>, responseTime_min: record<unit: string, label: string, aggregation: string>, responseTime_p50: record<unit: string, label: string, aggregation: string>, responseTime_p90: record<unit: string, label: string, aggregation: string>, responseTime_p95: record<unit: string, label: string, aggregation: string>, responseTime_p99: record<unit: string, label: string, aggregation: string>, responseTime_stddev: record<unit: string, label: string, aggregation: string>, responseTime_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/playwright-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# TCP checks
#
# GET /v1/analytics/tcp-checks/{id}
# operationId: getV1AnalyticsTcpchecksId
export def "analytics-tcp-checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer-2 # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for TCP Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<total: record<unit: string, label: string, aggregation: string>, dns: record<unit: string, label: string, aggregation: string>, connection: record<unit: string, label: string, aggregation: string>, data: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, total_avg: record<unit: string, label: string, aggregation: string>, total_max: record<unit: string, label: string, aggregation: string>, total_median: record<unit: string, label: string, aggregation: string>, total_min: record<unit: string, label: string, aggregation: string>, total_p50: record<unit: string, label: string, aggregation: string>, total_p90: record<unit: string, label: string, aggregation: string>, total_p95: record<unit: string, label: string, aggregation: string>, total_p99: record<unit: string, label: string, aggregation: string>, total_stddev: record<unit: string, label: string, aggregation: string>, total_sum: record<unit: string, label: string, aggregation: string>, dns_avg: record<unit: string, label: string, aggregation: string>, dns_max: record<unit: string, label: string, aggregation: string>, dns_median: record<unit: string, label: string, aggregation: string>, dns_min: record<unit: string, label: string, aggregation: string>, dns_p50: record<unit: string, label: string, aggregation: string>, dns_p90: record<unit: string, label: string, aggregation: string>, dns_p95: record<unit: string, label: string, aggregation: string>, dns_p99: record<unit: string, label: string, aggregation: string>, dns_stddev: record<unit: string, label: string, aggregation: string>, dns_sum: record<unit: string, label: string, aggregation: string>, connection_avg: record<unit: string, label: string, aggregation: string>, connection_max: record<unit: string, label: string, aggregation: string>, connection_median: record<unit: string, label: string, aggregation: string>, connection_min: record<unit: string, label: string, aggregation: string>, connection_p50: record<unit: string, label: string, aggregation: string>, connection_p90: record<unit: string, label: string, aggregation: string>, connection_p95: record<unit: string, label: string, aggregation: string>, connection_p99: record<unit: string, label: string, aggregation: string>, connection_stddev: record<unit: string, label: string, aggregation: string>, connection_sum: record<unit: string, label: string, aggregation: string>, data_avg: record<unit: string, label: string, aggregation: string>, data_max: record<unit: string, label: string, aggregation: string>, data_median: record<unit: string, label: string, aggregation: string>, data_min: record<unit: string, label: string, aggregation: string>, data_p50: record<unit: string, label: string, aggregation: string>, data_p90: record<unit: string, label: string, aggregation: string>, data_p95: record<unit: string, label: string, aggregation: string>, data_p99: record<unit: string, label: string, aggregation: string>, data_stddev: record<unit: string, label: string, aggregation: string>, data_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/tcp-checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# URL Monitors
#
# GET /v1/analytics/url-monitors/{id}
# operationId: getV1AnalyticsUrlmonitorsId
export def "analytics-url-monitors get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hours)
  --aggregationInterval: float # The time interval to use for aggregating metrics in minutes. For example, five minutes is 5, 24 hours is 1440. (e.g. 1440)
  --filterByStatus: list # Filter based on whether a check result was either failing or passing (e.g. [failure])
  --groupBy: string@groupBy-completer # Determines how the series data is grouped. Note that grouped queries are a bit more expensive and might take longer.
  --metrics: list # Available metrics for API Checks. You can pass multiple metrics as a comma separated string.
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkId: string, name: string, checkType: string, activated: bool, muted: bool, frequency: float, from: string, to: string, tags: list<string>, series: list<string>, pagination: record<page: float, limit: float>, metadata: record<responseTime: record<unit: string, label: string, aggregation: string>, wait: record<unit: string, label: string, aggregation: string>, dns: record<unit: string, label: string, aggregation: string>, tcp: record<unit: string, label: string, aggregation: string>, firstByte: record<unit: string, label: string, aggregation: string>, download: record<unit: string, label: string, aggregation: string>, availability: record<unit: string, label: string, aggregation: string>, retries: record<unit: string, label: string, aggregation: string>, responseTime_avg: record<unit: string, label: string, aggregation: string>, responseTime_max: record<unit: string, label: string, aggregation: string>, responseTime_median: record<unit: string, label: string, aggregation: string>, responseTime_min: record<unit: string, label: string, aggregation: string>, responseTime_p50: record<unit: string, label: string, aggregation: string>, responseTime_p90: record<unit: string, label: string, aggregation: string>, responseTime_p95: record<unit: string, label: string, aggregation: string>, responseTime_p99: record<unit: string, label: string, aggregation: string>, responseTime_stddev: record<unit: string, label: string, aggregation: string>, responseTime_sum: record<unit: string, label: string, aggregation: string>, wait_avg: record<unit: string, label: string, aggregation: string>, wait_max: record<unit: string, label: string, aggregation: string>, wait_median: record<unit: string, label: string, aggregation: string>, wait_min: record<unit: string, label: string, aggregation: string>, wait_p50: record<unit: string, label: string, aggregation: string>, wait_p90: record<unit: string, label: string, aggregation: string>, wait_p95: record<unit: string, label: string, aggregation: string>, wait_p99: record<unit: string, label: string, aggregation: string>, wait_stddev: record<unit: string, label: string, aggregation: string>, wait_sum: record<unit: string, label: string, aggregation: string>, dns_avg: record<unit: string, label: string, aggregation: string>, dns_max: record<unit: string, label: string, aggregation: string>, dns_median: record<unit: string, label: string, aggregation: string>, dns_min: record<unit: string, label: string, aggregation: string>, dns_p50: record<unit: string, label: string, aggregation: string>, dns_p90: record<unit: string, label: string, aggregation: string>, dns_p95: record<unit: string, label: string, aggregation: string>, dns_p99: record<unit: string, label: string, aggregation: string>, dns_stddev: record<unit: string, label: string, aggregation: string>, dns_sum: record<unit: string, label: string, aggregation: string>, tcp_avg: record<unit: string, label: string, aggregation: string>, tcp_max: record<unit: string, label: string, aggregation: string>, tcp_median: record<unit: string, label: string, aggregation: string>, tcp_min: record<unit: string, label: string, aggregation: string>, tcp_p50: record<unit: string, label: string, aggregation: string>, tcp_p90: record<unit: string, label: string, aggregation: string>, tcp_p95: record<unit: string, label: string, aggregation: string>, tcp_p99: record<unit: string, label: string, aggregation: string>, tcp_stddev: record<unit: string, label: string, aggregation: string>, tcp_sum: record<unit: string, label: string, aggregation: string>, firstByte_avg: record<unit: string, label: string, aggregation: string>, firstByte_max: record<unit: string, label: string, aggregation: string>, firstByte_median: record<unit: string, label: string, aggregation: string>, firstByte_min: record<unit: string, label: string, aggregation: string>, firstByte_p50: record<unit: string, label: string, aggregation: string>, firstByte_p90: record<unit: string, label: string, aggregation: string>, firstByte_p95: record<unit: string, label: string, aggregation: string>, firstByte_p99: record<unit: string, label: string, aggregation: string>, firstByte_stddev: record<unit: string, label: string, aggregation: string>, firstByte_sum: record<unit: string, label: string, aggregation: string>, download_avg: record<unit: string, label: string, aggregation: string>, download_max: record<unit: string, label: string, aggregation: string>, download_median: record<unit: string, label: string, aggregation: string>, download_min: record<unit: string, label: string, aggregation: string>, download_p50: record<unit: string, label: string, aggregation: string>, download_p90: record<unit: string, label: string, aggregation: string>, download_p95: record<unit: string, label: string, aggregation: string>, download_p99: record<unit: string, label: string, aggregation: string>, download_stddev: record<unit: string, label: string, aggregation: string>, download_sum: record<unit: string, label: string, aggregation: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "aggregationInterval" $aggregationInterval "scalar") (serialize-qp "filterByStatus" $filterByStatus "multi") (serialize-qp "groupBy" $groupBy "scalar") (serialize-qp "metrics" $metrics "multi") (serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/analytics/url-monitors/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get check status badge. You can enable the badges feature in <a href="https://app.checklyhq.com/settings/account/general">account settings</a>
#
# GET /v1/badges/checks/{checkId}
# operationId: getV1BadgesChecksCheckid
export def "badges-checks get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string@style-completer # default: flat
  --theme: string@theme-completer # default: default
  --responseTime: string@bool-completer # default: false
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar") (serialize-qp "theme" $theme "scalar") (serialize-qp "responseTime" $responseTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/badges/checks/($checkId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get group status badge. You can enable the badges feature in <a href="https://app.checklyhq.com/settings/account/general">account settings</a>
#
# GET /v1/badges/groups/{groupId}
# operationId: getV1BadgesGroupsGroupid
export def "badges-groups get" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --style: string@style-completer # default: flat
  --theme: string@theme-completer # default: default
  --responseTime: string@bool-completer # default: false
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "style" $style "scalar") (serialize-qp "theme" $theme "scalar") (serialize-qp "responseTime" $responseTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/badges/groups/($groupId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all alerts for your account
#
# GET /v1/check-alerts
# operationId: getV1Checkalerts
export def "check-alerts list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --qp-from: string # Select records up from this UNIX timestamp (>= date). Defaults to now - 6 hours. (format: date)
  --qp-to: string # Optional. Select records up to this UNIX timestamp (< date). Defaults to 6 hours after "from". (format: date)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, name: string, checkId: string, alertType: string, checkType: string, runLocation: string, responseTime: float, error: string, statusCode: string, created_at: string, startedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/check-alerts" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List alerts for a specific check
#
# GET /v1/check-alerts/{checkId}
# operationId: getV1CheckalertsCheckid
export def "check-alerts get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --qp-from: string # Select records up from this UNIX timestamp (>= date). Defaults to now - 6 hours. (format: date)
  --qp-to: string # Optional. Select records up to this UNIX timestamp (< date). Defaults to 6 hours after "from". (format: date)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, name: string, checkId: string, alertType: string, checkType: string, runLocation: string, responseTime: float, error: string, statusCode: string, created_at: string, startedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-alerts/($checkId)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all check groups
#
# GET /v1/check-groups
# operationId: getV1Checkgroups
export def "check-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --tag: list # Filters check groups by tags. Returns check groups that have at least one of the specified tags.
  --name: list # Filters check groups by exact name match. Accepts one or more names and returns groups that match any of the specified names.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list, queryParameters: list, assertions: list, basicAuth: record>, browserCheckDefaults: string, environmentVariables: list<record>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record, sslCertificates: record, runBasedEscalation: record, timeBasedEscalation: record, parallelRunFailureThreshold: record>, alertChannelSubscriptions: list<record>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "tag" $tag "multi") (serialize-qp "name" $name "multi")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/check-groups" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check group
#
# POST /v1/check-groups
# DEPRECATED
# operationId: postV1Checkgroups
# --apiCheckDefaults shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
# --environmentVariables item shape: {key?: string, value: string, locked?: bool, secret?: bool}
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
@deprecated
export def "check-groups post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check group. (e.g. Check group)
  --activated: string@bool-completer # Determines if the checks in the group are running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check in this group fails and/or recovers. (default: false)
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --locations: list # An array of one or more data center locations where to run the checks. (e.g. [us-east-1, eu-central-1])
  --concurrency: float # Determines how many checks are invoked concurrently when triggering a check group from CI/CD or through the API. (default: 3)
  --apiCheckDefaults: record # default: {}, e.g. {url: https://api.example.com/v1, headers: [{key: Cache-Control, value: no-store}], queryParameters: [{key: Page, value: 1}], assertions: [{source: STATUS_CODE, comparison: NOT_EMPTY, target: 200}], basicAuth: {username: admin, password: abc12345}} — shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --browserCheckDefaults: string
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute checks in this group. (nullable)
  --environmentVariables: list # nullable — item shape: {key?: string, value: string, locked?: bool, secret?: bool}
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check group. (default: true)
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check in this group. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check in this group. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase of an API check in this group. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase of an API check in this group. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the checks. (nullable, e.g. [data-center-eu])
  --runParallel: string@bool-completer # When true, the checks in the group will run in parallel in all selected locations. (default: false)
  --retryStrategy: any # Either a retry strategy object or the literal string "FALLBACK".
]: any -> record<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, browserCheckDefaults: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/check-groups" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, tags: $tags, locations: $locations, concurrency: $concurrency, apiCheckDefaults: $apiCheckDefaults, browserCheckDefaults: $browserCheckDefaults, runtimeId: $runtimeId, environmentVariables: $environmentVariables, doubleCheck: $doubleCheck, useGlobalAlertSettings: $useGlobalAlertSettings, alertSettings: $alertSettings, alertChannelSubscriptions: $alertChannelSubscriptions, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, privateLocations: $privateLocations, runParallel: $runParallel, retryStrategy: $retryStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve one check in a specific group with group settings applied
#
# GET /v1/check-groups/{groupId}/checks/{checkId}
# operationId: getV1CheckgroupsGroupidChecksCheckid
export def "check-groups-checks get" [
  groupId: int
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, checkType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-groups/($groupId)/checks/($checkId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a check group.
#
# DELETE /v1/check-groups/{id}
# operationId: deleteV1CheckgroupsId
export def "check-groups delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-groups/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a check group
#
# GET /v1/check-groups/{id}
# operationId: getV1CheckgroupsId
export def "check-groups get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, browserCheckDefaults: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-groups/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check group
#
# PUT /v1/check-groups/{id}
# DEPRECATED
# operationId: putV1CheckgroupsId
# --apiCheckDefaults shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
# --environmentVariables item shape: {key?: string, value: string, locked?: bool, secret?: bool}
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
@deprecated
export def "check-groups put-by-id" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check group. (e.g. Check group)
  --activated: string@bool-completer # Determines if the checks in the group are running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check in this group fails and/or recovers. (default: false)
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --locations: list # An array of one or more data center locations where to run the checks. (e.g. [us-east-1, eu-central-1])
  --concurrency: float # Determines how many checks are invoked concurrently when triggering a check group from CI/CD or through the API. (default: 3)
  --apiCheckDefaults: record # default: {}, e.g. {url: https://api.example.com/v1, headers: [{key: Cache-Control, value: no-store}], queryParameters: [{key: Page, value: 1}], assertions: [{source: STATUS_CODE, comparison: NOT_EMPTY, target: 200}], basicAuth: {username: admin, password: abc12345}} — shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --browserCheckDefaults: string
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute checks in this group. (nullable)
  --environmentVariables: list # nullable — item shape: {key?: string, value: string, locked?: bool, secret?: bool}
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check group. (default: true)
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check in this group. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check in this group. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase of an API check in this group. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase of an API check in this group. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the checks. (nullable, e.g. [data-center-eu])
  --runParallel: string@bool-completer # When true, the checks in the group will run in parallel in all selected locations. (default: false)
  --retryStrategy: any # Either a retry strategy object or the literal string "FALLBACK".
]: any -> record<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, browserCheckDefaults: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-groups/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, tags: $tags, locations: $locations, concurrency: $concurrency, apiCheckDefaults: $apiCheckDefaults, browserCheckDefaults: $browserCheckDefaults, runtimeId: $runtimeId, environmentVariables: $environmentVariables, doubleCheck: $doubleCheck, useGlobalAlertSettings: $useGlobalAlertSettings, alertSettings: $alertSettings, alertChannelSubscriptions: $alertChannelSubscriptions, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, privateLocations: $privateLocations, runParallel: $runParallel, retryStrategy: $retryStrategy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve all checks in a specific group with group settings applied
#
# GET /v1/check-groups/{id}/checks
# operationId: getV1CheckgroupsIdChecks
export def "check-groups-checks list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, checkType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-groups/($id)/checks" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all check results
#
# GET /v1/check-results/{checkId}
# DEPRECATED
# operationId: getV1CheckresultsCheckid
@deprecated
export def "check-results get-by-checkId" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --qp-from: string # Select records up from this UNIX timestamp (>= date). Defaults to now - 6 hours. (format: date)
  --qp-to: string # Optional. Select records up to this UNIX timestamp (< date). Defaults to 6 hours after "from". (format: date)
  --location: string@location-completer # Provide a data center location, e.g. "eu-west-1" to filter by location
  --checkType: string@checkType-completer # The type of the check
  --hasFailures: string@bool-completer # Check result has one or more failures
  --resultType: string@resultType-completer # The check result type (FINAL,ATTEMPT,ALL) (default: FINAL)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, name: string, checkId: string, hasFailures: bool, hasErrors: bool, isDegraded: bool, isCancelled: bool, overMaxResponseTime: bool, runLocation: string, startedAt: string, stoppedAt: string, created_at: string, responseTime: float, apiCheckResult: record<assertions: list, request: record, response: record, requestError: string, jobLog: record, jobAssets: list, pcapDataUrl: string>, browserCheckResult: record<type: string, traceSummary: record, pages: list, playwrightTestVideos: list, errors: list, endTime: float, startTime: float, runtimeVersion: string, jobLog: list, jobAssets: list, playwrightTestTraces: list, playwrightTestJsonReportFile: string>, multiStepCheckResult: record<errors: list, endTime: float, startTime: float, runtimeVersion: string, jobLog: list, jobAssets: list, playwrightTestTraces: list, playwrightTestJsonReportFile: string>, agenticCheckResult: record<summary: string, prompt: string, assertions: list, suggestions: list, steps: list, errors: list, artifactManifest: record>, playwrightCheckResult: record<errors: list, playwrightTraceFiles: list, jobLog: list, jobAssets: list, playwrightTestVideos: list, playwrightTestTraces: list, playwrightTestJsonReportFile: string>, checkRunId: float, attempts: float, resultType: string, sequenceId: string, traceId: string, errorGroupIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "checkType" $checkType "scalar") (serialize-qp "hasFailures" $hasFailures "scalar") (serialize-qp "resultType" $resultType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-results/($checkId)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a check result
#
# GET /v1/check-results/{checkId}/{checkResultId}
# operationId: getV1CheckresultsCheckidCheckresultid
export def "check-results get-by-checkId-checkResultId" [
  checkId: string
  checkResultId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, name: string, checkId: string, hasFailures: bool, hasErrors: bool, isDegraded: bool, isCancelled: bool, overMaxResponseTime: bool, runLocation: string, startedAt: string, stoppedAt: string, created_at: string, responseTime: float, apiCheckResult: record<assertions: list<string>, request: record<method: string, url: string, data: string, headers: record, params: record>, response: record<status: float, statusText: string, body: string, headers: record, timings: record, timingPhases: record>, requestError: string, jobLog: record, jobAssets: list<string>, pcapDataUrl: string>, browserCheckResult: record<type: string, traceSummary: record, pages: list<string>, playwrightTestVideos: list<string>, errors: list<string>, endTime: float, startTime: float, runtimeVersion: string, jobLog: list<string>, jobAssets: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, multiStepCheckResult: record<errors: list<string>, endTime: float, startTime: float, runtimeVersion: string, jobLog: list<string>, jobAssets: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, agenticCheckResult: record<summary: string, prompt: string, assertions: list<record>, suggestions: list<record>, steps: list<record>, errors: list<record>, artifactManifest: record>, playwrightCheckResult: record<errors: list<record>, playwrightTraceFiles: list<record>, jobLog: list<string>, jobAssets: list<string>, playwrightTestVideos: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, checkRunId: float, attempts: float, resultType: string, sequenceId: string, traceId: string, errorGroupIds: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-results/($checkId)/($checkResultId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a normalized asset manifest for a check result
#
# GET /v1/check-results/{checkId}/{checkResultId}/assets
# operationId: getV1CheckresultsCheckidCheckresultidAssets
export def "check-results-assets get" [
  checkId: string
  checkResultId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Filter assets by normalized asset type. Repeat the query parameter to include multiple types.
  --name: string # Glob pattern matched case-insensitively against the asset name and archive entry path. Empty patterns are ignored.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<assets: table<type: string, name: string, url: string, contentType: string, source: record, archive: record>, truncated: bool, entriesReturned: int, entriesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-results/($checkId)/($checkResultId)/assets" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a new check session
#
# POST /v1/check-sessions/trigger
# DEPRECATED
# operationId: postV1ChecksessionsTrigger
# --target shape: {matchTags?: list, checkId?: list}
@deprecated
export def "check-sessions-trigger post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --target: record # shape: {matchTags?: list, checkId?: list}
  --refreshCache: string@bool-completer # If true, the runner will skip existing caches and install dependencies from scratch. This applies only to Playwright Check Suites. (default: false)
]: any -> record<sessions: table<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list, runSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/check-sessions/trigger")
  let body = {target: $target, refreshCache: $refreshCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a check session
#
# GET /v1/check-sessions/{checkSessionId}
# DEPRECATED
# operationId: getV1ChecksessionsChecksessionid
@deprecated
export def "check-sessions get-by-checkSessionId" [
  checkSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
]: nothing -> record<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list<string>, runSource: string, results: table<checkResultId: string, checkResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, resultType: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool, isCancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-sessions/($checkSessionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a check session
#
# POST /v1/check-sessions/{checkSessionId}/cancel
# operationId: postV1ChecksessionsChecksessionidCancel
export def "check-sessions-cancel post" [
  checkSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --sequenceId: list # Subset of sequence IDs to cancel. Omit to cancel all in-progress sequences.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-sessions/($checkSessionId)/cancel")
  let body = {sequenceId: $sequenceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Await the completion of a check session
#
# GET /v1/check-sessions/{checkSessionId}/completion
# DEPRECATED
# operationId: getV1ChecksessionsChecksessionidCompletion
@deprecated
export def "check-sessions-completion get-by-checkSessionId" [
  checkSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxWaitSeconds: float # The maximum time to wait for completion, in seconds. (e.g. 30)
]: nothing -> record<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list<string>, runSource: string, results: table<checkResultId: string, checkResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, resultType: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool, isCancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxWaitSeconds" $maxWaitSeconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/check-sessions/($checkSessionId)/completion" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all check statuses
#
# GET /v1/check-statuses
# operationId: getV1Checkstatuses
export def "check-statuses list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<name: string, checkId: string, hasFailures: bool, hasErrors: bool, isDegraded: bool, longestRun: float, shortestRun: float, lastRunLocation: string, lastCheckRunId: string, sslDaysRemaining: float, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/check-statuses")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve check status details
#
# GET /v1/check-statuses/{checkId}
# operationId: getV1CheckstatusesCheckid
export def "check-statuses get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, checkId: string, hasFailures: bool, hasErrors: bool, isDegraded: bool, longestRun: float, shortestRun: float, lastRunLocation: string, lastCheckRunId: string, sslDaysRemaining: float, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/check-statuses/($checkId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all checks
#
# GET /v1/checks
# operationId: getV1Checks
export def "checks list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --apiCheckUrlFilterPattern: string # Filters the results by a string contained in the URL of an API check, for instance a domain like "www.myapp.com". Only returns API checks.
  --tag: list # Filters checks by tags. Returns checks that have at least one of the specified tags.
  --checkType: string@checkType-completer # Filters checks by type. Returns checks that match the specified type.
  --search: string # Filters checks by name using a case-insensitive partial match.
  --status: string@status-completer-1 # Filters checks by current status.
  --applyGroupSettings: string@bool-completer # Checks that belong to a group are returned with group settings applied. (default: false)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, checkType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "apiCheckUrlFilterPattern" $apiCheckUrlFilterPattern "scalar") (serialize-qp "tag" $tag "multi") (serialize-qp "checkType" $checkType "scalar") (serialize-qp "search" $search "scalar") (serialize-qp "status" $status "scalar") (serialize-qp "applyGroupSettings" $applyGroupSettings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a check
#
# POST /v1/checks
# DEPRECATED
# operationId: postV1Checks
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
@deprecated
export def "checks post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (nullable, default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  checkType: string@checkType-completer # The type of the check.
  --frequency: int # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --request: record
  heartbeat: record
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: any
  --maxResponseTime: any
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
]: any -> record<id: string, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, checkType: $checkType, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an API check
#
# POST /v1/checks/api
# operationId: postV1ChecksApi
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {method: "GET"|"POST"|"PUT"|"HEAD"|"DELETE"|"PATCH", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", body?: string, bodyType?: "JSON"|"FORM"|"RAW"|"GRAPHQL"|"NONE", headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
export def "checks post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  request: record # Determines the request that the check is going to run. — shape: {method: "GET"|"POST"|"PUT"|"HEAD"|"DELETE"|"PATCH", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", body?: string, bodyType?: "JSON"|"FORM"|"RAW"|"GRAPHQL"|"NONE", headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 5000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable, e.g. )
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable, e.g. )
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<method: string, url: string, followRedirects: bool, skipSSL: bool, ipFamily: string, body: string, bodyType: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, checkType: string, tearDownSnippetId: float, setupSnippetId: float, localSetupScript: string, localTearDownScript: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/api" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations, tearDownSnippetId: $tearDownSnippetId, setupSnippetId: $setupSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an API check
#
# PUT /v1/checks/api/{id}
# operationId: putV1ChecksApiId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {method: "GET"|"POST"|"PUT"|"HEAD"|"DELETE"|"PATCH", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", body?: string, bodyType?: "JSON"|"FORM"|"RAW"|"GRAPHQL"|"NONE", headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
export def "checks put-by-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --request: record # Determines the request that the check is going to run. — shape: {method: "GET"|"POST"|"PUT"|"HEAD"|"DELETE"|"PATCH", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", body?: string, bodyType?: "JSON"|"FORM"|"RAW"|"GRAPHQL"|"NONE", headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 5000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable, e.g. )
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable, e.g. )
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<method: string, url: string, followRedirects: bool, skipSSL: bool, ipFamily: string, body: string, bodyType: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, checkType: string, tearDownSnippetId: float, setupSnippetId: float, localSetupScript: string, localTearDownScript: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/api/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations, tearDownSnippetId: $tearDownSnippetId, setupSnippetId: $setupSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a browser check
#
# POST /v1/checks/browser
# operationId: postV1ChecksBrowser
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
export def "checks-browser post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. Use global environment variables whenever possible. (nullable, e.g. []) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --frequency: int@frequency-completer-1 # How often the check should run in minutes. (default: 10)
  --script: string # A valid piece of Node.js javascript code describing a browser interaction with the Playwright frameworks. (nullable, e.g. const { chromium } = require("playwright"); (async () => {    // launch the browser and open a new page   const browser = await chromium.launch();   const page = await browser.newPage();    // navigate to our target web page   await page.goto("https://danube-webshop.herokuapp.com/");    // click on the login button and go through the login procedure   await page.click("#login");   await page.type("#n-email", "user@email.com");   await page.type("#n-password2", "supersecure1");   await page.click("#goto-signin-btn");    // wait until the login confirmation message is shown   await page.waitForSelector("#login-message", { visible: true });    // close the browser and terminate the session   await browser.close(); })();)
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
  --sslCheckDomain: string # A valid fully qualified domain name (FQDN) to check its SSL certificate. (nullable, e.g. www.acme.com)
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, frequency: int, script: string, sslCheckDomain: string, privateLocations: list<string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/browser" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, environmentVariables: $environmentVariables, frequency: $frequency, script: $script, scriptPath: $scriptPath, privateLocations: $privateLocations, dependencies: $dependencies, sslCheckDomain: $sslCheckDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a browser check
#
# PUT /v1/checks/browser/{id}
# operationId: putV1ChecksBrowserId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
export def "checks-browser put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. Use global environment variables whenever possible. (nullable, e.g. []) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --frequency: int@frequency-completer-1 # How often the check should run in minutes. (default: 10)
  --script: string # A valid piece of Node.js javascript code describing a browser interaction with the Playwright frameworks. (nullable, e.g. const { chromium } = require("playwright"); (async () => {    // launch the browser and open a new page   const browser = await chromium.launch();   const page = await browser.newPage();    // navigate to our target web page   await page.goto("https://danube-webshop.herokuapp.com/");    // click on the login button and go through the login procedure   await page.click("#login");   await page.type("#n-email", "user@email.com");   await page.type("#n-password2", "supersecure1");   await page.click("#goto-signin-btn");    // wait until the login confirmation message is shown   await page.waitForSelector("#login-message", { visible: true });    // close the browser and terminate the session   await browser.close(); })();)
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
  --sslCheckDomain: string # A valid fully qualified domain name (FQDN) to check its SSL certificate. (nullable, e.g. www.acme.com)
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, frequency: int, script: string, sslCheckDomain: string, privateLocations: list<string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/browser/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, environmentVariables: $environmentVariables, frequency: $frequency, script: $script, scriptPath: $scriptPath, privateLocations: $privateLocations, dependencies: $dependencies, sslCheckDomain: $sslCheckDomain} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an DNS monitor
#
# POST /v1/checks/dns
# operationId: postV1ChecksDns
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {query: string, nameServer?: string, port?: float, recordType: "A"|"AAAA"|"CNAME"|"MX"|"TXT"|"SOA"|"NS", assertions?: list, protocol?: "TCP"|"UDP"}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
export def "checks-dns post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  request: record # Determines the request that the DNS monitor is going to run. — shape: {query: string, nameServer?: string, port?: float, recordType: "A"|"AAAA"|"CNAME"|"MX"|"TXT"|"SOA"|"NS", assertions?: list, protocol?: "TCP"|"UDP"}
  heartbeat: record
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 500)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 1000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<query: string, nameServer: string, port: float, recordType: string, assertions: list<record>, protocol: string>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/dns" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an DNS Monitor
#
# PUT /v1/checks/dns/{id}
# operationId: putV1ChecksDnsId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --alertChannels shape: {email?: list, webhook?: list, slack?: list, sms?: list}
# --request shape: {query: string, nameServer?: string, port?: float, recordType: "A"|"AAAA"|"CNAME"|"MX"|"TXT"|"SOA"|"NS", assertions?: list, protocol?: "TCP"|"UDP"}
export def "checks-dns put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --body-id: string # e.g. 9d6df684-0bc3-4a38-a094-4e97627dd93e
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (nullable, default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # nullable
  --maxResponseTime: float # nullable
  --created-at: string # format: date
  --updated-at: string # nullable, format: date-time
  --alertChannels: record # nullable — shape: {email?: list, webhook?: list, slack?: list, sms?: list}
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --request: record # Determines the request that the DNS monitor is going to run. — shape: {query: string, nameServer?: string, port?: float, recordType: "A"|"AAAA"|"CNAME"|"MX"|"TXT"|"SOA"|"NS", assertions?: list, protocol?: "TCP"|"UDP"}
  --checkType: string@checkType-completer-1
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<query: string, nameServer: string, port: float, recordType: string, assertions: list<record>, protocol: string>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/dns/($id)" $qp)
  let body = {id: $body_id, name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, created_at: $created_at, updated_at: $updated_at, alertChannels: $alertChannels, privateLocations: $privateLocations, request: $request, checkType: $checkType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a heartbeat check
#
# POST /v1/checks/heartbeat
# operationId: postV1ChecksHeartbeat
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --heartbeat shape: {period: float, periodUnit: "seconds"|"minutes"|"hours"|"days", grace: float, graceUnit: "seconds"|"minutes"|"hours"|"days", pingToken?: string}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
export def "checks-heartbeat post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int
  --request: record
  heartbeat: record # shape: {period: float, periodUnit: "seconds"|"minutes"|"hours"|"days", grace: float, graceUnit: "seconds"|"minutes"|"hours"|"days", pingToken?: string}
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 10000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
]: any -> record<id: string, name: string, activated: bool, muted: bool, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, heartbeat: record<period: float, periodUnit: string, grace: float, graceUnit: string, pingToken: string, pingUrl: string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/heartbeat" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a heartbeat check
#
# PUT /v1/checks/heartbeat/{id}
# operationId: putV1ChecksHeartbeatId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --heartbeat shape: {period: float, periodUnit: "seconds"|"minutes"|"hours"|"days", grace: float, graceUnit: "seconds"|"minutes"|"hours"|"days", pingToken?: string}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
export def "checks-heartbeat put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int
  --request: record
  --heartbeat: record # shape: {period: float, periodUnit: "seconds"|"minutes"|"hours"|"days", grace: float, graceUnit: "seconds"|"minutes"|"hours"|"days", pingToken?: string}
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 10000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
]: any -> record<id: string, name: string, activated: bool, muted: bool, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, heartbeat: record<period: float, periodUnit: string, grace: float, graceUnit: string, pingToken: string, pingUrl: string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/heartbeat/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get heartbeat availability
#
# GET /v1/checks/heartbeats/{checkId}/availability
# operationId: getV1ChecksHeartbeatsCheckidAvailability
export def "checks-heartbeats-availability get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # format: date, default: 2026-06-10T20:27:20.531Z
  --endTime: string # format: date, default: 2026-06-11T20:27:20.531Z
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<successRatio: record<previousPeriod: float, currentPeriod: float>, totalEntitiesCurrentPeriod: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/heartbeats/($checkId)/availability" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of events for a heartbeat
#
# GET /v1/checks/heartbeats/{checkId}/events
# operationId: getV1ChecksHeartbeatsCheckidEvents
export def "checks-heartbeats-events list" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --startTime: string # format: date, default: 2026-06-10T20:27:20.534Z
  --endTime: string # format: date, default: 2026-06-11T20:27:20.534Z
  --limit: float # default: 10
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<events: list<record>, stats: record<last24Hours: record, last7Days: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "startTime" $startTime "scalar") (serialize-qp "endTime" $endTime "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/heartbeats/($checkId)/events" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a specific Heartbeat event
#
# GET /v1/checks/heartbeats/{checkId}/events/{id}
# operationId: getV1ChecksHeartbeatsCheckidEventsId
export def "checks-heartbeats-events get" [
  checkId: string
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<event: record<id: string, state: string, timestamp: string, source: string, userAgent: string>, stats: record<last24Hours: record<successRatio: record, totalEntitiesCurrentPeriod: float>, last7Days: record<successRatio: record, totalEntitiesCurrentPeriod: float>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/checks/heartbeats/($checkId)/events/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an ICMP monitor
#
# POST /v1/checks/icmp
# operationId: postV1ChecksIcmp
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {hostname: string, ipFamily?: "IPv4"|"IPv6", pingCount?: int, assertions?: list}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
export def "checks-icmp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  request: record # Determines the request that the ICMP monitor is going to run. — shape: {hostname: string, ipFamily?: "IPv4"|"IPv6", pingCount?: int, assertions?: list}
  heartbeat: record
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 10000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
  --degradedPacketLossThreshold: float # The packet loss percentage threshold for degraded state. Must be greater than 0. (nullable, default: 10)
  --maxPacketLossThreshold: float # The packet loss percentage threshold for failed state. Must be greater than 0 and greater than or equal to degradedPacketLossThreshold. (nullable, default: 20)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, degradedPacketLossThreshold: float, maxPacketLossThreshold: float, privateLocations: list<string>, request: record<hostname: string, ipFamily: string, pingCount: int, assertions: list<record>>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/icmp" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, degradedPacketLossThreshold: $degradedPacketLossThreshold, maxPacketLossThreshold: $maxPacketLossThreshold, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an ICMP Monitor
#
# PUT /v1/checks/icmp/{id}
# operationId: putV1ChecksIcmpId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {hostname: string, ipFamily?: "IPv4"|"IPv6", pingCount?: int, assertions?: list}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
export def "checks-icmp put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --request: record # Determines the request that the ICMP monitor is going to run. — shape: {hostname: string, ipFamily?: "IPv4"|"IPv6", pingCount?: int, assertions?: list}
  heartbeat: record
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 10000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 20000)
  --degradedPacketLossThreshold: float # The packet loss percentage threshold for degraded state. Must be greater than 0. (nullable, default: 10)
  --maxPacketLossThreshold: float # The packet loss percentage threshold for failed state. Must be greater than 0 and greater than or equal to degradedPacketLossThreshold. (nullable, default: 20)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, degradedPacketLossThreshold: float, maxPacketLossThreshold: float, privateLocations: list<string>, request: record<hostname: string, ipFamily: string, pingCount: int, assertions: list<record>>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/icmp/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, degradedPacketLossThreshold: $degradedPacketLossThreshold, maxPacketLossThreshold: $maxPacketLossThreshold, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a multi-step check
#
# POST /v1/checks/multistep
# operationId: postV1ChecksMultistep
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
export def "checks-multistep post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --checkType: string@checkType-completer-2 # default: MULTI_STEP
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. Use global environment variables whenever possible. (nullable, e.g. []) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --frequency: int@frequency-completer-1 # How often the check should run in minutes. (default: 10)
  --script: string # A valid piece of Node.js javascript code describing a multi-step API interaction with the Playwright frameworks. (nullable, e.g. const { chromium } = require("playwright"); (async () => {    // launch the browser and open a new page   const browser = await chromium.launch();   const page = await browser.newPage();    // navigate to our target web page   await page.goto("https://danube-webshop.herokuapp.com/");    // click on the login button and go through the login procedure   await page.click("#login");   await page.type("#n-email", "user@email.com");   await page.type("#n-password2", "supersecure1");   await page.click("#goto-signin-btn");    // wait until the login confirmation message is shown   await page.waitForSelector("#login-message", { visible: true });    // close the browser and terminate the session   await browser.close(); })();)
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, frequency: int, script: string, privateLocations: list<string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, created_at: string, updated_at: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/multistep" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, checkType: $checkType, environmentVariables: $environmentVariables, frequency: $frequency, script: $script, scriptPath: $scriptPath, privateLocations: $privateLocations, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a multi-step check
#
# PUT /v1/checks/multistep/{id}
# operationId: putV1ChecksMultistepId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
export def "checks-multistep put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --checkType: string@checkType-completer-2 # default: MULTI_STEP
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. Use global environment variables whenever possible. (nullable, e.g. []) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --frequency: int@frequency-completer-1 # How often the check should run in minutes. (default: 10)
  --script: string # A valid piece of Node.js javascript code describing a multi-step API interaction with the Playwright frameworks. (nullable, e.g. const { chromium } = require("playwright"); (async () => {    // launch the browser and open a new page   const browser = await chromium.launch();   const page = await browser.newPage();    // navigate to our target web page   await page.goto("https://danube-webshop.herokuapp.com/");    // click on the login button and go through the login procedure   await page.click("#login");   await page.type("#n-email", "user@email.com");   await page.type("#n-password2", "supersecure1");   await page.click("#goto-signin-btn");    // wait until the login confirmation message is shown   await page.waitForSelector("#login-message", { visible: true });    // close the browser and terminate the session   await browser.close(); })();)
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, checkType: string, frequency: int, script: string, privateLocations: list<string>, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, created_at: string, updated_at: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/multistep/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, checkType: $checkType, environmentVariables: $environmentVariables, frequency: $frequency, script: $script, scriptPath: $scriptPath, privateLocations: $privateLocations, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a TCP check
#
# POST /v1/checks/tcp
# operationId: postV1ChecksTcp
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {hostname?: string, port: float, data?: string, assertions?: list, ipFamily?: "IPv4"|"IPv6"}
export def "checks-tcp post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  request: record # shape: {hostname?: string, port: float, data?: string, assertions?: list, ipFamily?: "IPv4"|"IPv6"}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 3000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 5000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<hostname: string, port: float, data: string, assertions: list<record>, ipFamily: string>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/tcp" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an TCP check
#
# PUT /v1/checks/tcp/{id}
# operationId: putV1ChecksTcpId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {hostname?: string, port: float, data?: string, assertions?: list, ipFamily?: "IPv4"|"IPv6"}
export def "checks-tcp put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --request: record # shape: {hostname?: string, port: float, data?: string, assertions?: list, ipFamily?: "IPv4"|"IPv6"}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 3000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 5000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<hostname: string, port: float, data: string, assertions: list<record>, ipFamily: string>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/tcp/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a URL monitor
#
# POST /v1/checks/url
# operationId: postV1ChecksUrl
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {method?: "GET", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", assertions?: list}
export def "checks-url post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  request: record # Determines the request that the check is going to run. — shape: {method?: "GET", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", assertions?: list}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 3000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 5000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<method: string, url: string, followRedirects: bool, skipSSL: bool, ipFamily: string, assertions: list<record>>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/checks/url" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update an URL Monitor
#
# PUT /v1/checks/url/{id}
# operationId: putV1ChecksUrlId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --request shape: {method?: "GET", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", assertions?: list}
export def "checks-url put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --request: record # Determines the request that the check is going to run. — shape: {method?: "GET", url: string, followRedirects?: bool, skipSSL?: bool, ipFamily?: "IPv4"|"IPv6", assertions?: list}
  --frequency: int@frequency-completer # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API & TCP checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --degradedResponseTime: float # The response time in milliseconds where a check should be considered degraded. (nullable, default: 3000)
  --maxResponseTime: float # The response time in milliseconds where a check should be considered failing. (nullable, default: 5000)
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
]: any -> record<id: string, name: string, activated: bool, muted: bool, doubleCheck: bool, shouldFail: bool, locations: list<string>, tags: list<string>, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, useGlobalAlertSettings: bool, groupId: float, groupOrder: float, runtimeId: string, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, retryStrategy: record<type: string, baseBackoffSeconds: float, sameRegion: bool, maxRetries: float, maxDurationSeconds: float, onlyOn: list<string>>, triggerIncident: record<serviceId: string, severity: string, name: string, description: string, notifySubscribers: bool>, runParallel: bool, description: string, frequency: int, frequencyOffset: int, degradedResponseTime: float, maxResponseTime: float, created_at: string, updated_at: string, alertChannels: record<email: list<record>, webhook: list<record>, slack: list<record>, sms: list<record>>, privateLocations: list<string>, request: record<method: string, url: string, followRedirects: bool, skipSSL: bool, ipFamily: string, assertions: list<record>>, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/url/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, request: $request, frequency: $frequency, frequencyOffset: $frequencyOffset, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a check
#
# DELETE /v1/checks/{id}
# operationId: deleteV1ChecksId
export def "checks delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/checks/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a check
#
# GET /v1/checks/{id}
# operationId: getV1ChecksId
export def "checks get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeDependencies: string@bool-completer # Include check dependencies in the response
  --applyGroupSettings: string@bool-completer # Checks that belong to a group are returned with group settings applied. (default: false)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, checkType: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeDependencies" $includeDependencies "scalar") (serialize-qp "applyGroupSettings" $applyGroupSettings "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a check
#
# PUT /v1/checks/{id}
# DEPRECATED
# operationId: putV1ChecksId
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --retryStrategy shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
# --triggerIncident shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
# --environmentVariables item shape: {key: string, value: string, locked?: bool, secret?: bool}
# --dependencies item shape: {path: string, content: string}
@deprecated
export def "checks put-by-id-1" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The name of the check. (e.g. Check)
  --activated: string@bool-completer # Determines if the check is running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check fails and/or recovers. (default: false)
  --doubleCheck: string@bool-completer # [Deprecated] Retry failed check runs. This property is deprecated, and `retryStrategy` can be used instead. (default: true)
  --shouldFail: string@bool-completer # Allows to invert the behaviour of when a check is considered to fail. Allows for validating error status like 404. (default: false)
  --locations: list # An array of one or more data center locations where to run this check. (nullable, e.g. [us-east-1, eu-central-1])
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --alertSettings: record # Alert settings. (nullable, default: {escalationType: RUN_BASED, runBasedEscalation: {failedRunThreshold: 1}, reminders: {amount: 0, interval: 5}, parallelRunFailureThreshold: {enabled: false, percentage: 10}}) — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", reminders?: record, sslCertificates?: record, runBasedEscalation?: record, timeBasedEscalation?: record, parallelRunFailureThreshold?: record}
  --useGlobalAlertSettings: string@bool-completer # When true, the account level alert setting will be used, not the alert setting defined on this check. (default: true)
  --groupId: float # The id of the check group this check is part of. (nullable)
  --groupOrder: float # The position of this check in a check group. It determines in what order checks are run when a group is triggered from the API or from CI/CD. (nullable)
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute this check. (nullable)
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --retryStrategy: record # The strategy to determine how failed checks are retried. (nullable) — shape: {type: "FIXED"|"LINEAR"|"EXPONENTIAL"|"SINGLE_RETRY", baseBackoffSeconds?: float, sameRegion?: bool, maxRetries?: float, maxDurationSeconds?: float, onlyOn?: list}
  --triggerIncident: record # Determines whether the check or monitor should create and resolve an incident based on its alert configuration. Useful for status page automation. (nullable) — shape: {serviceId: string, severity: "CRITICAL"|"MAJOR"|"MEDIUM"|"MINOR", name: string, description: string, notifySubscribers: bool}
  --runParallel: string@bool-completer # When true, the check will run in parallel in all selected locations. (default: false)
  --description: string # A description of the check. (nullable)
  --checkType: string@checkType-completer # The type of the check.
  --frequency: int # How often the check should run in minutes. (default: 10)
  --frequencyOffset: int # Used for setting seconds for check frequencies under 1 minutes (only for API checks) and spreading checks over a time range for frequencies over 1 minute. This works as follows: Checks with a frequency of 0 can have a frequencyOffset of 10, 20 or 30 meaning they will run every 10, 20 or 30 seconds. Checks with a frequency lower than and equal to 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.floor(frequency * 10)", i.e. for a check that runs every 5 minutes the max frequencyOffset is 50. Checks with a frequency higher than 60 can have a frequencyOffset between 1 and a max value based on the formula "Math.ceil(frequency / 60)", i.e. for a check that runs every 720 minutes, the max frequencyOffset is 12. 
  --request: record
  heartbeat: record
  script: string
  --scriptPath: string # Path of the script in the runtime. (nullable)
  --sslCheckDomain: string
  --environmentVariables: list # Key/value pairs for setting environment variables during check execution. These are only relevant for Browser checks. Use global environment variables whenever possible. (nullable) — item shape: {key: string, value: string, locked?: bool, secret?: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase. (nullable)
  --degradedResponseTime: any
  --maxResponseTime: any
  --privateLocations: list # An array of one or more private locations where to run the check. (nullable, e.g. [data-center-eu])
  --dependencies: list # An array of BCR dependency files. (nullable) — item shape: {path: string, content: string}
]: any -> record<id: string, checkType: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/checks/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, doubleCheck: $doubleCheck, shouldFail: $shouldFail, locations: $locations, tags: $tags, alertSettings: $alertSettings, useGlobalAlertSettings: $useGlobalAlertSettings, groupId: $groupId, groupOrder: $groupOrder, runtimeId: $runtimeId, alertChannelSubscriptions: $alertChannelSubscriptions, retryStrategy: $retryStrategy, triggerIncident: $triggerIncident, runParallel: $runParallel, description: $description, checkType: $checkType, frequency: $frequency, frequencyOffset: $frequencyOffset, request: $request, heartbeat: $heartbeat, script: $script, scriptPath: $scriptPath, sslCheckDomain: $sslCheckDomain, environmentVariables: $environmentVariables, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, degradedResponseTime: $degradedResponseTime, maxResponseTime: $maxResponseTime, privateLocations: $privateLocations, dependencies: $dependencies} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all client certificates.
#
# GET /v1/client-certificates
# operationId: getV1Clientcertificates
export def "client-certificates list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<host: string, cert: string, ca: string, id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client-certificates")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Creates a new client certificate.
#
# POST /v1/client-certificates
# operationId: postV1Clientcertificates
export def "client-certificates post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  host: string # The host domain for the certificate without https://. You can use wildcards to match domains, e.g. "*.acme.com" (e.g. www.acme.com)
  cert: string # The client certificate in PEM format as a string. This string should retain any line breaks, e.g. it should start similar to this "-----BEGIN CERTIFICATE-----\nMIIEnTCCAoWgAwIBAgIJAL+WugL...
  --ca: string # An optional CA certificate in PEM format as a string. (nullable)
  --key: string # The private key in PEM format as a string.
  --passphrase: string # An optional passphrase for the private key. Your passphrase is stored encrypted at rest. (nullable)
]: any -> record<host: string, cert: string, ca: string, id: string, created_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/client-certificates")
  let body = {host: $host, cert: $cert, ca: $ca, key: $key, passphrase: $passphrase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Deletes a client certificate.
#
# DELETE /v1/client-certificates/{id}
# operationId: deleteV1ClientcertificatesId
export def "client-certificates delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client-certificates/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows one client certificate.
#
# GET /v1/client-certificates/{id}
# operationId: getV1ClientcertificatesId
export def "client-certificates get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<host: string, cert: string, ca: string, id: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/client-certificates/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all dashboards
#
# GET /v1/dashboards
# operationId: getV1Dashboards
export def "dashboards list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<customDomain: string, customUrl: string, logo: string, favicon: string, link: string, description: string, width: string, refreshRate: float, paginate: bool, paginationRate: float, checksPerPage: float, useTagsAndOperator: bool, hideTags: bool, enableIncidents: bool, expandChecks: bool, tags: list<string>, showHeader: bool, showCheckRunLinks: bool, showGroupNames: bool, customCSS: string, isPrivate: bool, showP95: bool, showP99: bool, keys: list<record>, id: float, dashboardId: string, created_at: string, header: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/dashboards" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a dashboard
#
# POST /v1/dashboards
# operationId: postV1Dashboards
# --keys item shape: {id: string, rawKey: string, maskedKey: string, created_at: string, updated_at?: string}
export def "dashboards post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --customUrl: string # A subdomain name under "checklyhq.com". Needs to be unique across all users. (e.g. status)
  --customDomain: string # A custom user domain, e.g. "status.example.com". See the docs on updating your DNS and SSL usage. (nullable, e.g. https://status.mycompany.com/)
  --logo: string # A URL pointing to an image file. (nullable, e.g. https://static.mycompany.com/static/images/logo.svg)
  --favicon: string # A URL pointing to an image file used as dashboard favicon. (nullable, e.g. https://static.mycompany.com/static/images/icon.svg)
  --link: string # A URL link to redirect when dashboard logo is clicked on. (nullable, e.g. https://www.mycompany.com/)
  header: string # A piece of text displayed at the top of your dashboard. (e.g. My company status)
  --description: string # A piece of text displayed below the header or title of your dashboard. (nullable, e.g. My dashboard description)
  --width: string@width-completer # Determines whether to use the full screen or focus in the center. (default: FULL)
  --refreshRate: float@refreshRate-completer # How often to refresh the dashboard in seconds. (default: 60)
  --paginate: string@bool-completer # Determines of pagination is on or off. (default: true)
  --paginationRate: float@paginationRate-completer # How often to trigger pagination in seconds. (default: 60)
  --checksPerPage: float # Number of checks displayed per page. (nullable, default: 15)
  --useTagsAndOperator: string@bool-completer # When to use AND operator for tags lookup. (nullable, default: false)
  --hideTags: string@bool-completer # Show or hide the tags on the dashboard. (default: false)
  --enableIncidents: string@bool-completer # Enable or disable incidents on the dashboard. (default: false)
  --expandChecks: string@bool-completer # Expand or collapse checks on the dashboard. (default: false)
  --tags: list # A list of one or more tags that filter which checks to display on the dashboard. (e.g. [production])
  --showHeader: string@bool-completer # Show or hide header and description on the dashboard. (default: true)
  --showCheckRunLinks: string@bool-completer # Show or hide check run links on the dashboard. (default: false)
  --showGroupNames: string@bool-completer # Show or hide group names on the dashboard. (default: true)
  --customCSS: string # Custom CSS to be applied to the dashboard. (nullable, default: )
  --isPrivate: string@bool-completer # Determines if the dashboard is public or private. (default: false)
  --showP95: string@bool-completer # Show or hide the P95 stats on the dashboard. (default: true)
  --showP99: string@bool-completer # Show or hide the P99 stats on the dashboard. (default: true)
  --keys: list # Show key for private dashboard. — item shape: {id: string, rawKey: string, maskedKey: string, created_at: string, updated_at?: string}
]: any -> record<customDomain: string, customUrl: string, logo: string, favicon: string, link: string, description: string, width: string, refreshRate: float, paginate: bool, paginationRate: float, checksPerPage: float, useTagsAndOperator: bool, hideTags: bool, enableIncidents: bool, expandChecks: bool, tags: list<string>, showHeader: bool, showCheckRunLinks: bool, showGroupNames: bool, customCSS: string, isPrivate: bool, showP95: bool, showP99: bool, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, id: float, dashboardId: string, created_at: string, header: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/dashboards")
  let body = {customUrl: $customUrl, customDomain: $customDomain, logo: $logo, favicon: $favicon, link: $link, header: $header, description: $description, width: $width, refreshRate: $refreshRate, paginate: $paginate, paginationRate: $paginationRate, checksPerPage: $checksPerPage, useTagsAndOperator: $useTagsAndOperator, hideTags: $hideTags, enableIncidents: $enableIncidents, expandChecks: $expandChecks, tags: $tags, showHeader: $showHeader, showCheckRunLinks: $showCheckRunLinks, showGroupNames: $showGroupNames, customCSS: $customCSS, isPrivate: $isPrivate, showP95: $showP95, showP99: $showP99, keys: $keys} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a dashboard
#
# DELETE /v1/dashboards/{dashboardId}
# operationId: deleteV1DashboardsDashboardid
export def "dashboards delete" [
  dashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/($dashboardId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a dashboard
#
# GET /v1/dashboards/{dashboardId}
# operationId: getV1DashboardsDashboardid
export def "dashboards get" [
  dashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: string@type-completer-2
]: nothing -> record<customDomain: string, customUrl: string, logo: string, favicon: string, link: string, description: string, width: string, refreshRate: float, paginate: bool, paginationRate: float, checksPerPage: float, useTagsAndOperator: bool, hideTags: bool, enableIncidents: bool, expandChecks: bool, tags: list<string>, showHeader: bool, showCheckRunLinks: bool, showGroupNames: bool, customCSS: string, isPrivate: bool, showP95: bool, showP99: bool, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, id: float, dashboardId: string, created_at: string, header: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/dashboards/($dashboardId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a dashboard
#
# PUT /v1/dashboards/{dashboardId}
# operationId: putV1DashboardsDashboardid
# --keys item shape: {id: string, rawKey: string, maskedKey: string, created_at: string, updated_at?: string}
export def "dashboards put" [
  dashboardId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --customDomain: string # A custom user domain, e.g. "status.example.com". See the docs on updating your DNS and SSL usage. (nullable, e.g. https://status.mycompany.com/)
  --customUrl: string # A subdomain name under "checklyhq.com". Needs to be unique across all users. (e.g. status)
  --logo: string # A URL pointing to an image file. (nullable, e.g. https://static.mycompany.com/static/images/logo.svg)
  --favicon: string # A URL pointing to an image file used as dashboard favicon. (nullable, e.g. https://static.mycompany.com/static/images/icon.svg)
  --link: string # A URL link to redirect when dashboard logo is clicked on. (nullable, e.g. https://www.mycompany.com/)
  --description: string # A piece of text displayed below the header or title of your dashboard. (nullable, e.g. My dashboard description)
  --width: string@width-completer # Determines whether to use the full screen or focus in the center. (default: FULL)
  --refreshRate: float@refreshRate-completer # How often to refresh the dashboard in seconds. (default: 60)
  --paginate: string@bool-completer # Determines of pagination is on or off. (default: true)
  --paginationRate: float@paginationRate-completer # How often to trigger pagination in seconds. (default: 60)
  --checksPerPage: float # Number of checks displayed per page. (nullable, default: 15)
  --useTagsAndOperator: string@bool-completer # When to use AND operator for tags lookup. (nullable, default: false)
  --hideTags: string@bool-completer # Show or hide the tags on the dashboard. (default: false)
  --enableIncidents: string@bool-completer # Enable or disable incidents on the dashboard. (default: false)
  --expandChecks: string@bool-completer # Expand or collapse checks on the dashboard. (default: false)
  --tags: list # A list of one or more tags that filter which checks to display on the dashboard. (e.g. [production])
  --showHeader: string@bool-completer # Show or hide header and description on the dashboard. (default: true)
  --showCheckRunLinks: string@bool-completer # Show or hide check run links on the dashboard. (default: false)
  --showGroupNames: string@bool-completer # Show or hide group names on the dashboard. (default: true)
  --customCSS: string # Custom CSS to be applied to the dashboard. (nullable, default: )
  --isPrivate: string@bool-completer # Determines if the dashboard is public or private. (default: false)
  --showP95: string@bool-completer # Show or hide the P95 stats on the dashboard. (default: true)
  --showP99: string@bool-completer # Show or hide the P99 stats on the dashboard. (default: true)
  --keys: list # Show key for private dashboard. — item shape: {id: string, rawKey: string, maskedKey: string, created_at: string, updated_at?: string}
  --header: string # A piece of text displayed at the top of your dashboard. (e.g. My company status)
]: any -> record<customDomain: string, customUrl: string, logo: string, favicon: string, link: string, description: string, width: string, refreshRate: float, paginate: bool, paginationRate: float, checksPerPage: float, useTagsAndOperator: bool, hideTags: bool, enableIncidents: bool, expandChecks: bool, tags: list<string>, showHeader: bool, showCheckRunLinks: bool, showGroupNames: bool, customCSS: string, isPrivate: bool, showP95: bool, showP99: bool, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, id: float, dashboardId: string, created_at: string, header: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/dashboards/($dashboardId)")
  let body = {customDomain: $customDomain, customUrl: $customUrl, logo: $logo, favicon: $favicon, link: $link, description: $description, width: $width, refreshRate: $refreshRate, paginate: $paginate, paginationRate: $paginationRate, checksPerPage: $checksPerPage, useTagsAndOperator: $useTagsAndOperator, hideTags: $hideTags, enableIncidents: $enableIncidents, expandChecks: $expandChecks, tags: $tags, showHeader: $showHeader, showCheckRunLinks: $showCheckRunLinks, showGroupNames: $showGroupNames, customCSS: $customCSS, isPrivate: $isPrivate, showP95: $showP95, showP99: $showP99, keys: $keys, header: $header} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all error groups in your account.
#
# GET /v1/error-groups
# operationId: getV1Errorgroups
export def "error-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, checkId: string, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, rootCauseAnalyses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/error-groups" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all error groups for a specific check.
#
# GET /v1/error-groups/checks/{checkId}
# operationId: getV1ErrorgroupsChecksCheckid
export def "error-groups-checks get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, checkId: string, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, rootCauseAnalyses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/error-groups/checks/($checkId)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve one error group.
#
# GET /v1/error-groups/{id}
# operationId: getV1ErrorgroupsId
export def "error-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, checkId: string, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, rootCauseAnalyses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/error-groups/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an error group. Mainly used for archiving error groups.
#
# PATCH /v1/error-groups/{id}
# operationId: patchV1ErrorgroupsId
export def "error-groups patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --archiveForEver: string@bool-completer
  --archivedUntilNextEvent: string@bool-completer
]: any -> record<id: string, checkId: string, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, rootCauseAnalyses: list<record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/error-groups/($id)")
  let body = {archiveForEver: $archiveForEver, archivedUntilNextEvent: $archivedUntilNextEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an incident
#
# POST /v1/incidents
# operationId: postV1Incidents
# --incidentUpdates item shape: {status: "INVESTIGATING"|"IDENTIFIED"|"MONITORING"|"RESOLVED"|"MAINTENANCE", description: string}
export def "incidents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # A name used to describe the incident. (e.g. Service outage)
  impact: string@impact-completer # Used to indicate the impact or severity. (default: MINOR, e.g. MINOR)
  --startedAt: string # Used to indicate when incident starts to be active. (nullable, format: date-time, e.g. 2022-11-25T12:34:56.000Z)
  --stoppedAt: string # Used to indicate when incident turns to inactive. (nullable, format: date-time, e.g. 2022-11-25T13:34:56.000Z)
  dashboardId: float # The dashboard ID where the incident will be shown. (e.g. 1234)
  incidentUpdates: list # The first incident update with the status and description. It must be only one element. (e.g. [{status: INVESTIGATING, description: The service is down and affects all the regions.}]) — item shape: {status: "INVESTIGATING"|"IDENTIFIED"|"MONITORING"|"RESOLVED"|"MAINTENANCE", description: string}
]: any -> record<name: string, impact: string, startedAt: string, stoppedAt: string, dashboardId: float, id: string, created_at: string, updated_at: string, incidentUpdates: table<status: string, description: string, id: string, created_at: string, updated_at: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/incidents")
  let body = {name: $name, impact: $impact, startedAt: $startedAt, stoppedAt: $stoppedAt, dashboardId: $dashboardId, incidentUpdates: $incidentUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an incident
#
# DELETE /v1/incidents/{id}
# operationId: deleteV1IncidentsId
export def "incidents delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an incident
#
# GET /v1/incidents/{id}
# operationId: getV1IncidentsId
export def "incidents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --includeAllIncidentUpdates: string@bool-completer # You use it to include all the incident updates. (default: false, e.g. true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, impact: string, startedAt: string, stoppedAt: string, dashboardId: float, id: string, created_at: string, updated_at: string, incidentUpdates: table<status: string, description: string, id: string, created_at: string, updated_at: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeAllIncidentUpdates" $includeAllIncidentUpdates "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($id)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an incident
#
# PUT /v1/incidents/{id}
# operationId: putV1IncidentsId
export def "incidents put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --probe: string@bool-completer
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # A name used to describe the incident. (e.g. Service outage)
  impact: string@impact-completer # Used to indicate the impact or severity. (default: MINOR, e.g. MINOR)
  --startedAt: string # Used to indicate when incident starts to be active. (nullable, format: date-time, e.g. 2022-11-25T12:34:56.000Z)
  --stoppedAt: string # Used to indicate when incident turns to inactive. (nullable, format: date-time, e.g. 2022-11-25T13:34:56.000Z)
]: any -> record<name: string, impact: string, startedAt: string, stoppedAt: string, dashboardId: float, id: string, created_at: string, updated_at: string, incidentUpdates: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "probe" $probe "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/incidents/($id)" $qp)
  let body = {name: $name, impact: $impact, startedAt: $startedAt, stoppedAt: $stoppedAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create an incident update
#
# POST /v1/incidents/{incidentId}/updates
# operationId: postV1IncidentsIncidentidUpdates
export def "incidents-updates post" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  status: string@status-completer-2 # The incident update status. Must be one of INVESTIGATING,IDENTIFIED,MONITORING,RESOLVED,MAINTENANCE (e.g. INVESTIGATING)
  description: string # A description about the status update. (e.g. We found the issue and we are working on it.)
]: any -> table<status: string, description: string, id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incidentId)/updates")
  let body = {status: $status, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an incident update
#
# DELETE /v1/incidents/{incidentId}/updates/{id}
# operationId: deleteV1IncidentsIncidentidUpdatesId
export def "incidents-updates delete" [
  id: string
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incidentId)/updates/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an incident update
#
# PUT /v1/incidents/{incidentId}/updates/{id}
# operationId: putV1IncidentsIncidentidUpdatesId
export def "incidents-updates put" [
  id: string
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  description: string # A description about the status update. (e.g. We found the issue and we are working on it.)
]: any -> record<status: string, description: string, id: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/incidents/($incidentId)/updates/($id)")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all supported locations
#
# GET /v1/locations
# operationId: getV1Locations
export def "locations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<region: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/locations")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all maintenance windows
#
# GET /v1/maintenance-windows
# operationId: getV1Maintenancewindows
export def "maintenance-windows list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --startsAt: string # Filter for items which startsAt field matches the constraint
  --endsAt: string # Filter for items which endsAt field matches the constraint
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: float, name: string, tags: list<string>, startsAt: string, endsAt: string, repeatInterval: float, repeatUnit: string, repeatEndsAt: string, description: string, statusPageVisibility: record<enabled: bool, severity: string, affectAllServices: bool, suppressAutoIncidents: bool, notifyOnStart: bool, notifyOnEnd: bool, reminderMinutesBefore: list, autoStart: bool, autoEnd: bool, statusPageIds: list, serviceIds: list>, pauseAllChecks: bool, silenceAlertsTags: list<string>, silenceAllAlerts: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar") (serialize-qp "startsAt" $startsAt "scalar") (serialize-qp "endsAt" $endsAt "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/maintenance-windows" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a maintenance window
#
# POST /v1/maintenance-windows
# operationId: postV1Maintenancewindows
# --statusPageVisibility shape: {enabled?: bool, severity?: "MINOR"|"MEDIUM"|"MAJOR"|"CRITICAL", affectAllServices?: bool, notifyOnStart?: bool, notifyOnEnd?: bool, suppressAutoIncidents?: bool, reminderMinutesBefore?: list, autoStart?: bool, autoEnd?: bool, statusPageIds?: list, serviceIds?: list}
export def "maintenance-windows post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The maintenance window name. (e.g. Maintenance Window)
  --tags: list # The names of the checks and groups maintenance window should apply to. (e.g. [production])
  startsAt: string # The start date of the maintenance window. (format: date, e.g. 2022-08-24)
  endsAt: string # The end date of the maintenance window. (format: date, e.g. 2022-08-25)
  --repeatInterval: float # The repeat interval of the maintenance window from the first occurance. (nullable)
  repeatUnit: string # The repeat strategy for the maintenance window. (e.g. DAY)
  --repeatEndsAt: string # The end date where the maintenance window should stop repeating. (nullable, format: date)
  --pauseAllChecks: string@bool-completer # Whether to pause all checks in the account (overrides tag scope). (default: false)
  --silenceAlertsTags: list # Tags defining which checks have alerts silenced (when silenceAllAlerts is false).
  --silenceAllAlerts: string@bool-completer # Whether to silence alerts for all checks (overrides silenceAlertsTags scope). (default: false)
  --description: string # A description of the maintenance window. When the window is visible on status pages, this description is shown there too. (nullable)
  --statusPageVisibility: record # Status page visibility and subscriber-facing maintenance settings. (default: {}) — shape: {enabled?: bool, severity?: "MINOR"|"MEDIUM"|"MAJOR"|"CRITICAL", affectAllServices?: bool, notifyOnStart?: bool, notifyOnEnd?: bool, suppressAutoIncidents?: bool, reminderMinutesBefore?: list, autoStart?: bool, autoEnd?: bool, statusPageIds?: list, serviceIds?: list}
]: any -> record<id: float, name: string, tags: list<string>, startsAt: string, endsAt: string, repeatInterval: float, repeatUnit: string, repeatEndsAt: string, description: string, statusPageVisibility: record<enabled: bool, severity: string, affectAllServices: bool, suppressAutoIncidents: bool, notifyOnStart: bool, notifyOnEnd: bool, reminderMinutesBefore: list<int>, autoStart: bool, autoEnd: bool, statusPageIds: list<string>, serviceIds: list<string>>, pauseAllChecks: bool, silenceAlertsTags: list<string>, silenceAllAlerts: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/maintenance-windows")
  let body = {name: $name, tags: $tags, startsAt: $startsAt, endsAt: $endsAt, repeatInterval: $repeatInterval, repeatUnit: $repeatUnit, repeatEndsAt: $repeatEndsAt, pauseAllChecks: $pauseAllChecks, silenceAlertsTags: $silenceAlertsTags, silenceAllAlerts: $silenceAllAlerts, description: $description, statusPageVisibility: $statusPageVisibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maintenance window
#
# DELETE /v1/maintenance-windows/{id}
# operationId: deleteV1MaintenancewindowsId
export def "maintenance-windows delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a maintenance window
#
# GET /v1/maintenance-windows/{id}
# operationId: getV1MaintenancewindowsId
export def "maintenance-windows get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, name: string, tags: list<string>, startsAt: string, endsAt: string, repeatInterval: float, repeatUnit: string, repeatEndsAt: string, description: string, statusPageVisibility: record<enabled: bool, severity: string, affectAllServices: bool, suppressAutoIncidents: bool, notifyOnStart: bool, notifyOnEnd: bool, reminderMinutesBefore: list<int>, autoStart: bool, autoEnd: bool, statusPageIds: list<string>, serviceIds: list<string>>, pauseAllChecks: bool, silenceAlertsTags: list<string>, silenceAllAlerts: bool, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance window
#
# PUT /v1/maintenance-windows/{id}
# operationId: putV1MaintenancewindowsId
# --statusPageVisibility shape: {enabled?: bool, severity?: "MINOR"|"MEDIUM"|"MAJOR"|"CRITICAL", affectAllServices?: bool, notifyOnStart?: bool, notifyOnEnd?: bool, suppressAutoIncidents?: bool, reminderMinutesBefore?: list, autoStart?: bool, autoEnd?: bool, statusPageIds?: list, serviceIds?: list}
export def "maintenance-windows put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --name: string # The maintenance window name. (e.g. Maintenance Window)
  --tags: list # The names of the checks and groups maintenance window should apply to. (e.g. [production])
  --startsAt: string # The start date of the maintenance window. (format: date, e.g. 2022-08-24)
  --endsAt: string # The end date of the maintenance window. (format: date, e.g. 2022-08-25)
  --repeatInterval: float # The repeat interval of the maintenance window from the first occurance. (nullable)
  --repeatEndsAt: string # The end date where the maintenance window should stop repeating. (nullable, format: date)
  --pauseAllChecks: string@bool-completer # Whether to pause all checks in the account (overrides tag scope). (default: false)
  --silenceAlertsTags: list # Tags defining which checks have alerts silenced (when silenceAllAlerts is false).
  --silenceAllAlerts: string@bool-completer # Whether to silence alerts for all checks (overrides silenceAlertsTags scope). (default: false)
  --description: string # A description of the maintenance window. When the window is visible on status pages, this description is shown there too. (nullable)
  --statusPageVisibility: record # Status page visibility and subscriber-facing maintenance settings. (default: {}) — shape: {enabled?: bool, severity?: "MINOR"|"MEDIUM"|"MAJOR"|"CRITICAL", affectAllServices?: bool, notifyOnStart?: bool, notifyOnEnd?: bool, suppressAutoIncidents?: bool, reminderMinutesBefore?: list, autoStart?: bool, autoEnd?: bool, statusPageIds?: list, serviceIds?: list}
  --repeatUnit: string@repeatUnit-completer # nullable
]: any -> record<id: float, name: string, tags: list<string>, startsAt: string, endsAt: string, repeatInterval: float, repeatUnit: string, repeatEndsAt: string, description: string, statusPageVisibility: record<enabled: bool, severity: string, affectAllServices: bool, suppressAutoIncidents: bool, notifyOnStart: bool, notifyOnEnd: bool, reminderMinutesBefore: list<int>, autoStart: bool, autoEnd: bool, statusPageIds: list<string>, serviceIds: list<string>>, pauseAllChecks: bool, silenceAlertsTags: list<string>, silenceAllAlerts: bool, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)")
  let body = {name: $name, tags: $tags, startsAt: $startsAt, endsAt: $endsAt, repeatInterval: $repeatInterval, repeatEndsAt: $repeatEndsAt, pauseAllChecks: $pauseAllChecks, silenceAlertsTags: $silenceAlertsTags, silenceAllAlerts: $silenceAllAlerts, description: $description, statusPageVisibility: $statusPageVisibility, repeatUnit: $repeatUnit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List maintenances for a maintenance window
#
# GET /v1/maintenance-windows/{id}/maintenances
# operationId: getV1MaintenancewindowsIdMaintenances
export def "maintenance-windows-maintenances list" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --page: int # default: 1
  --limit: int # default: 10
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, maintenanceWindowId: float, startsAt: string, endsAt: string, status: string, created_at: string, updated_at: string, updates: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "page" $page "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete a maintenance
#
# DELETE /v1/maintenance-windows/{id}/maintenances/{maintenanceId}
# operationId: deleteV1MaintenancewindowsIdMaintenancesMaintenanceid
export def "maintenance-windows-maintenances delete" [
  id: int
  maintenanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a maintenance
#
# GET /v1/maintenance-windows/{id}/maintenances/{maintenanceId}
# operationId: getV1MaintenancewindowsIdMaintenancesMaintenanceid
export def "maintenance-windows-maintenances get" [
  id: int
  maintenanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, maintenanceWindowId: float, startsAt: string, endsAt: string, status: string, created_at: string, updated_at: string, updates: table<id: string, maintenanceWindowId: float, maintenanceId: string, status: string, description: string, notifySubscribers: bool, created_at: string, previousStatus: string, previousStartsAt: string, previousEndsAt: string, dateAdjustments: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update maintenance dates
#
# PATCH /v1/maintenance-windows/{id}/maintenances/{maintenanceId}
# operationId: patchV1MaintenancewindowsIdMaintenancesMaintenanceid
export def "maintenance-windows-maintenances patch" [
  id: int
  maintenanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --startsAt: string # format: date
  --endsAt: string # format: date
]: any -> record<id: string, maintenanceWindowId: float, startsAt: string, endsAt: string, status: string, created_at: string, updated_at: string, updates: table<id: string, maintenanceWindowId: float, maintenanceId: string, status: string, description: string, notifySubscribers: bool, created_at: string, previousStatus: string, previousStartsAt: string, previousEndsAt: string, dateAdjustments: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)")
  let body = {startsAt: $startsAt, endsAt: $endsAt} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a maintenance window status update
#
# POST /v1/maintenance-windows/{id}/maintenances/{maintenanceId}/updates
# operationId: postV1MaintenancewindowsIdMaintenancesMaintenanceidUpdates
export def "maintenance-windows-maintenances-updates post" [
  id: int
  maintenanceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  status: string@status-completer-3 # The lifecycle status of this update.
  description: string # A description of the update.
  --notifySubscribers: string@bool-completer # Whether to notify status page subscribers about this update. (default: false)
]: any -> record<id: string, maintenanceWindowId: float, maintenanceId: string, status: string, description: string, notifySubscribers: bool, created_at: string, previousStatus: string, previousStartsAt: string, previousEndsAt: string, dateAdjustments: record<startsAt: string, endsAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)/updates")
  let body = {status: $status, description: $description, notifySubscribers: $notifySubscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a maintenance window status update
#
# DELETE /v1/maintenance-windows/{id}/maintenances/{maintenanceId}/updates/{updateId}
# operationId: deleteV1MaintenancewindowsIdMaintenancesMaintenanceidUpdatesUpdateid
export def "maintenance-windows-maintenances-updates delete" [
  id: int
  maintenanceId: string
  updateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)/updates/($updateId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a maintenance window status update
#
# PUT /v1/maintenance-windows/{id}/maintenances/{maintenanceId}/updates/{updateId}
# operationId: putV1MaintenancewindowsIdMaintenancesMaintenanceidUpdatesUpdateid
export def "maintenance-windows-maintenances-updates put" [
  id: int
  maintenanceId: string
  updateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --status: string@status-completer-3 # The lifecycle status of this update. Optional. When omitted, the stored status is preserved.
  description: string # A description of the update.
]: any -> record<id: string, maintenanceWindowId: float, maintenanceId: string, status: string, description: string, notifySubscribers: bool, created_at: string, previousStatus: string, previousStartsAt: string, previousEndsAt: string, dateAdjustments: record<startsAt: string, endsAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/maintenance-windows/($id)/maintenances/($maintenanceId)/updates/($updateId)")
  let body = {status: $status, description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List all private locations
#
# GET /v1/private-locations
# operationId: getV1Privatelocations
export def "private-locations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --versions: string@bool-completer # default: false
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, name: string, slugName: string, icon: string, created_at: string, updated_at: string, keys: list<record>, proxyUrl: string, lastSeen: string, agentCount: float, minAgentVersion: string, runningAgents: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "versions" $versions "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/private-locations" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a private location
#
# POST /v1/private-locations
# operationId: postV1Privatelocations
export def "private-locations post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name assigned to the private location. (e.g. New Private Location)
  slugName: string # Valid slug name. (e.g. new-private-location)
  --icon: string # default: location, e.g. location
  --proxyUrl: string # A proxy for outgoing API check HTTP calls from your private location. (nullable, e.g. https://user:password@164.92.149.127:3128)
]: any -> record<id: string, name: string, slugName: string, icon: string, created_at: string, updated_at: string, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, proxyUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/private-locations")
  let body = {name: $name, slugName: $slugName, icon: $icon, proxyUrl: $proxyUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Remove a private location
#
# DELETE /v1/private-locations/{id}
# operationId: deleteV1PrivatelocationsId
export def "private-locations delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/private-locations/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a private location
#
# GET /v1/private-locations/{id}
# operationId: getV1PrivatelocationsId
export def "private-locations get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, name: string, slugName: string, icon: string, created_at: string, updated_at: string, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, proxyUrl: string, lastSeen: string, agentCount: float, minAgentVersion: string, runningAgents: table<version: string, isOutdated: bool, count: float, agents: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/private-locations/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a private location
#
# PUT /v1/private-locations/{id}
# operationId: putV1PrivatelocationsId
export def "private-locations put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name assigned to the private location. (e.g. New Private Location)
  --icon: string # e.g. location
  --proxyUrl: string # A proxy for outgoing API check HTTP calls from your private location. (nullable, e.g. https://user:password@164.92.149.127:3128)
]: any -> record<id: string, name: string, slugName: string, icon: string, created_at: string, updated_at: string, keys: table<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string>, proxyUrl: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/private-locations/($id)")
  let body = {name: $name, icon: $icon, proxyUrl: $proxyUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a new API Key for a private location
#
# POST /v1/private-locations/{id}/keys
# operationId: postV1PrivatelocationsIdKeys
export def "private-locations-keys post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, rawKey: string, maskedKey: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/private-locations/($id)/keys")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Remove an existing API key for a private location
#
# DELETE /v1/private-locations/{id}/keys/{keyId}
# operationId: deleteV1PrivatelocationsIdKeysKeyid
export def "private-locations-keys delete" [
  id: string
  keyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/private-locations/($id)/keys/($keyId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get private location health metrics from a window of time.
#
# GET /v1/private-locations/{id}/metrics
# operationId: getV1PrivatelocationsIdMetrics
export def "private-locations-metrics get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Select metrics beginning with this UNIX timestamp. Must be less than 15 days ago. (format: date)
  --qp-to: string # Select metrics up to this UNIX timestamp. (format: date)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<timestamps: list<string>, queueSize: list<float>, oldestScheduledCheckRun: list<float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/private-locations/($id)/metrics" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generates a report with aggregate statistics for checks and check groups.
#
# GET /v1/reporting
# operationId: getV1Reporting
export def "reporting get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Custom start time of reporting window in unix timestamp format. Setting a custom "from" timestamp overrides the use of any "quickRange". (format: date)
  --qp-to: string # Custom end time of reporting window in unix timestamp format. Setting a custom "to" timestamp overrides the use of any "quickRange". (format: date)
  --quickRange: string@quickRange-completer-2 # Preset reporting windows are used for quickly generating report on commonly used windows. Can be overridden by using a custom "to" and "from" timestamp. (default: last24Hrs)
  --filterByTags: list # Use tags to filter the checks you want to see in your report. (e.g. [production])
  --deactivated: string@bool-completer # Filter checks by activated status. When set to true, only deactivated checks are returned. When set to false, only activated checks are returned. When omitted, all checks are returned. (nullable)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<name: string, checkId: string, checkType: string, deactivated: bool, tags: list<string>, aggregate: record<successRatio: float, avg: float, p95: float, p99: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "quickRange" $quickRange "scalar") (serialize-qp "filterByTags" $filterByTags "multi") (serialize-qp "deactivated" $deactivated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/reporting" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Generate a Root Cause Analysis for a check error group
#
# POST /v1/root-cause-analyses/error-groups/{errorGroupId}
# operationId: postV1RootcauseanalysesErrorgroupsErrorgroupid
export def "root-cause-analyses-error-groups post" [
  errorGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --userContext: string # Optional user defined context to provide extra details useful for the user impact and root cause analysis. (nullable, default: )
]: any -> record<id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/root-cause-analyses/error-groups/($errorGroupId)")
  let body = {userContext: $userContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate a Root Cause Analysis for a test session error group
#
# POST /v1/root-cause-analyses/test-session-error-groups/{testSessionErrorGroupId}
# operationId: postV1RootcauseanalysesTestsessionerrorgroupsTestsessionerrorgroupid
export def "root-cause-analyses-test-session-error-groups post" [
  testSessionErrorGroupId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --userContext: string # Optional user defined context to provide extra details useful for the user impact and root cause analysis. (nullable, default: )
]: any -> record<id: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/root-cause-analyses/test-session-error-groups/($testSessionErrorGroupId)")
  let body = {userContext: $userContext} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Root Cause Analysis
#
# GET /v1/root-cause-analyses/{id}
# operationId: getV1RootcauseanalysesId
export def "root-cause-analyses get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, checkType: string, provider: string, model: string, checkId: string, errorGroupId: string, durationMs: float, analysis: record<classification: string, userImpact: string, rootCause: string, codeFix: string, evidence: list<record>, referenceLinks: list<record>>, status: string, created_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/root-cause-analyses/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all supported runtimes
#
# GET /v1/runtimes
# operationId: getV1Runtimes
export def "runtimes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<name: string, multiStepSupport: bool, nodeJsVersion: string, stage: string, runtimeEndOfLife: string, description: string, dependencies: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/runtimes")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Shows details for one specific runtime
#
# GET /v1/runtimes/{id}
# operationId: getV1RuntimesId
export def "runtimes get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, multiStepSupport: bool, nodeJsVersion: string, stage: string, runtimeEndOfLife: string, description: string, dependencies: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/runtimes/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all snippets
#
# GET /v1/snippets
# operationId: getV1Snippets
export def "snippets list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: float, name: string, script: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/snippets" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a snippet
#
# POST /v1/snippets
# operationId: postV1Snippets
export def "snippets post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The snippet name. (e.g. Snippet)
  script: string # Your Node.js code that interacts with the API check lifecycle, or functions as a partial for browser checks. (e.g. request.url = request.url + '/extra')
]: any -> record<id: float, name: string, script: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/snippets")
  let body = {name: $name, script: $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a snippet
#
# DELETE /v1/snippets/{id}
# operationId: deleteV1SnippetsId
export def "snippets delete" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/snippets/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a snippet
#
# GET /v1/snippets/{id}
# operationId: getV1SnippetsId
export def "snippets get" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, name: string, script: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/snippets/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a snippet
#
# PUT /v1/snippets/{id}
# operationId: putV1SnippetsId
export def "snippets put" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The snippet name. (e.g. Snippet)
  script: string # Your Node.js code that interacts with the API check lifecycle, or functions as a partial for browser checks. (e.g. request.url = request.url + '/extra')
]: any -> record<id: float, name: string, script: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/snippets/($id)")
  let body = {name: $name, script: $script} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all source IPs for check runs
#
# GET /v1/static-ips
# operationId: getV1Staticips
export def "static-ips get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ips")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all source IPs for check runs
#
# GET /v1/static-ips-by-region
# operationId: getV1Staticipsbyregion
export def "static-ips-by-region get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ips-by-region")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all source IPs for check runs as txt file
#
# GET /v1/static-ips.txt
# operationId: getV1Staticipstxt
export def "static-ipstxt get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ips.txt")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all source IPv6s for check runs
#
# GET /v1/static-ipv6s
# operationId: getV1Staticipv6s
export def "static-ipv6s get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ipv6s")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all source IPv6s for check runs
#
# GET /v1/static-ipv6s-by-region
# operationId: getV1Staticipv6sbyregion
export def "static-ipv6s-by-region get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ipv6s-by-region")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Lists all source IPv6s for check runs as a txt file
#
# GET /v1/static-ipv6s.txt
# operationId: getV1Staticipv6stxt
export def "static-ipv6stxt get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/static-ipv6s.txt")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve all status pages.
#
# GET /v1/status-pages
# operationId: getV1Statuspages
export def "status-pages list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 20
  --nextId: string
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<length: int, entries: table<name: string, description: string, url: string, customDomain: string, themeColors: record, logo: string, redirectTo: string, favicon: string, defaultTheme: string, cards: list, id: string, accountId: string, created_at: string, updated_at: string, incidents: list, isPrivate: bool, keys: list>, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/status-pages" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new status page.
#
# POST /v1/status-pages
# operationId: postV1Statuspages
# --themeColors shape: {light: record, dark: record}
# --cards item shape: {id?: string, statusPageId?: string, name: string, services?: list}
export def "status-pages post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string
  --description: string # nullable
  --body-url: string
  --customDomain: string # A custom user domain, e.g. "status.example.com". See the docs on updating your DNS and SSL usage. (nullable)
  --themeColors: record # nullable — shape: {light: record, dark: record}
  --logo: string # nullable
  --redirectTo: string # nullable
  --favicon: string # nullable
  --defaultTheme: string@defaultTheme-completer # default: AUTO
  cards: list # item shape: {id?: string, statusPageId?: string, name: string, services?: list}
]: any -> record<name: string, description: string, url: string, customDomain: string, themeColors: record<light: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>, dark: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>>, logo: string, redirectTo: string, favicon: string, defaultTheme: string, cards: table<id: string, name: string, services: list, created_at: string, updated_at: string>, id: string, whiteLabel: bool, isPrivate: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/status-pages")
  let body = {name: $name, description: $description, url: $body_url, customDomain: $customDomain, themeColors: $themeColors, logo: $logo, redirectTo: $redirectTo, favicon: $favicon, defaultTheme: $defaultTheme, cards: $cards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the latest incidents with pagination.
#
# GET /v1/status-pages/incidents
# operationId: getV1StatuspagesIncidents
export def "status-pages-incidents list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 20
  --nextId: string
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<length: int, entries: table<name: string, severity: string, id: string, services: list, incidentUpdates: list, lastUpdateStatus: string, duration: int, created_at: string, updated_at: string>, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/status-pages/incidents" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a new incident.
#
# POST /v1/status-pages/incidents
# operationId: postV1StatuspagesIncidents
# --services item shape: {name: string, id: string, accountId: string, created_at?: string, updated_at?: string}
# --incidentUpdates item shape: {id?: string, description: string, status?: "INVESTIGATING"|"IDENTIFIED"|"MONITORING"|"RESOLVED", publicIncidentUpdateDate?: string, created_at?: string, notifySubscribers?: bool}
export def "status-pages-incidents post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --id: string
  --created-at: string # format: date
  --updated-at: string # format: date
  --lastUpdateStatus: string@lastUpdateStatus-completer
  name: string
  severity: string@severity-completer
  services: list # item shape: {name: string, id: string, accountId: string, created_at?: string, updated_at?: string}
  --duration: int # nullable
  incidentUpdates: list # item shape: {id?: string, description: string, status?: "INVESTIGATING"|"IDENTIFIED"|"MONITORING"|"RESOLVED", publicIncidentUpdateDate?: string, created_at?: string, notifySubscribers?: bool}
]: any -> record<name: string, severity: string, id: string, services: table<name: string, id: string, accountId: string, created_at: string, updated_at: string>, incidentUpdates: table<description: string, status: string, publicIncidentUpdateDate: string, notifySubscribers: bool, id: string, created_at: string>, lastUpdateStatus: string, duration: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/status-pages/incidents")
  let body = {id: $id, created_at: $created_at, updated_at: $updated_at, lastUpdateStatus: $lastUpdateStatus, name: $name, severity: $severity, services: $services, duration: $duration, incidentUpdates: $incidentUpdates} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an incident.
#
# DELETE /v1/status-pages/incidents/{incidentId}
# operationId: deleteV1StatuspagesIncidentsIncidentid
export def "status-pages-incidents delete" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an incident by id.
#
# GET /v1/status-pages/incidents/{incidentId}
# operationId: getV1StatuspagesIncidentsIncidentid
export def "status-pages-incidents get" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, severity: string, id: string, services: table<name: string, id: string, accountId: string, created_at: string, updated_at: string>, incidentUpdates: table<description: string, status: string, publicIncidentUpdateDate: string, notifySubscribers: bool, id: string, created_at: string>, lastUpdateStatus: string, duration: int, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing incident.
#
# PUT /v1/status-pages/incidents/{incidentId}
# operationId: putV1StatuspagesIncidentsIncidentid
# --services item shape: {name: string, id: string, accountId: string, created_at?: string, updated_at?: string}
export def "status-pages-incidents put" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --id: string
  --created-at: string # format: date
  --updated-at: string # format: date
  --lastUpdateStatus: string@lastUpdateStatus-completer
  name: string
  severity: string@severity-completer
  services: list # item shape: {name: string, id: string, accountId: string, created_at?: string, updated_at?: string}
  --duration: int # nullable
]: any -> record<name: string, severity: string, id: string, services: table<name: string, id: string, accountId: string, created_at: string, updated_at: string>, incidentUpdates: table<description: string, status: string, publicIncidentUpdateDate: string, notifySubscribers: bool, id: string, created_at: string>, lastUpdateStatus: string, duration: int, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)")
  let body = {id: $id, created_at: $created_at, updated_at: $updated_at, lastUpdateStatus: $lastUpdateStatus, name: $name, severity: $severity, services: $services, duration: $duration} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve the 100 latest incident updates of a specific incident.
#
# GET /v1/status-pages/incidents/{incidentId}/incident-updates
# operationId: getV1StatuspagesIncidentsIncidentidIncidentupdates
export def "status-pages-incidents-incident-updates list" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, description: string, status: string, publicIncidentUpdateDate: string, created_at: string, notifySubscribers: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)/incident-updates")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Add a new incident update to a specific incident.
#
# POST /v1/status-pages/incidents/{incidentId}/incident-updates
# operationId: postV1StatuspagesIncidentsIncidentidIncidentupdates
export def "status-pages-incidents-incident-updates post" [
  incidentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --id: string
  description: string
  --status: string@status-completer-4
  --publicIncidentUpdateDate: string # format: date-time, default: 2026-06-11T20:27:21.790Z
  --created-at: string # format: date
  --notifySubscribers: string@bool-completer # default: false
]: any -> record<id: string, description: string, status: string, publicIncidentUpdateDate: string, created_at: string, notifySubscribers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)/incident-updates")
  let body = {id: $id, description: $description, status: $status, publicIncidentUpdateDate: $publicIncidentUpdateDate, created_at: $created_at, notifySubscribers: $notifySubscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an incident update.
#
# DELETE /v1/status-pages/incidents/{incidentId}/incident-updates/{incidentUpdateId}
# operationId: deleteV1StatuspagesIncidentsIncidentidIncidentupdatesIncidentupdateid
export def "status-pages-incidents-incident-updates delete" [
  incidentId: string
  incidentUpdateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)/incident-updates/($incidentUpdateId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an incident update by id.
#
# GET /v1/status-pages/incidents/{incidentId}/incident-updates/{incidentUpdateId}
# operationId: getV1StatuspagesIncidentsIncidentidIncidentupdatesIncidentupdateid
export def "status-pages-incidents-incident-updates get" [
  incidentId: string
  incidentUpdateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, description: string, status: string, publicIncidentUpdateDate: string, created_at: string, notifySubscribers: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)/incident-updates/($incidentUpdateId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing incident update.
#
# PUT /v1/status-pages/incidents/{incidentId}/incident-updates/{incidentUpdateId}
# operationId: putV1StatuspagesIncidentsIncidentidIncidentupdatesIncidentupdateid
export def "status-pages-incidents-incident-updates put" [
  incidentId: string
  incidentUpdateId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --id: string
  description: string
  --status: string@status-completer-4
  --publicIncidentUpdateDate: string # format: date-time, default: 2026-06-11T20:27:21.790Z
  --created-at: string # format: date
  --notifySubscribers: string@bool-completer # default: false
]: any -> record<id: string, description: string, status: string, publicIncidentUpdateDate: string, created_at: string, notifySubscribers: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/incidents/($incidentId)/incident-updates/($incidentUpdateId)")
  let body = {id: $id, description: $description, status: $status, publicIncidentUpdateDate: $publicIncidentUpdateDate, created_at: $created_at, notifySubscribers: $notifySubscribers} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all services
#
# GET /v1/status-pages/services
# operationId: getV1StatuspagesServices
export def "status-pages-services list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # default: 20
  --nextId: string
  --paginated: string@bool-completer # default: true
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<length: int, entries: table<name: string, id: string, accountId: string, created_at: string, updated_at: string>, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar") (serialize-qp "paginated" $paginated "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/status-pages/services" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create a service
#
# POST /v1/status-pages/services
# operationId: postV1StatuspagesServices
export def "status-pages-services post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string
]: any -> record<name: string, id: string, accountId: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/status-pages/services")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a service
#
# DELETE /v1/status-pages/services/{serviceId}
# operationId: deleteV1StatuspagesServicesServiceid
export def "status-pages-services delete" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/services/($serviceId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a single service
#
# GET /v1/status-pages/services/{serviceId}
# operationId: getV1StatuspagesServicesServiceid
export def "status-pages-services get" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, id: string, accountId: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/services/($serviceId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a service
#
# PUT /v1/status-pages/services/{serviceId}
# operationId: putV1StatuspagesServicesServiceid
export def "status-pages-services put" [
  serviceId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string
]: any -> record<name: string, id: string, accountId: string, created_at: string, updated_at: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/services/($serviceId)")
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a status page.
#
# DELETE /v1/status-pages/{statusPageId}
# operationId: deleteV1StatuspagesStatuspageid
export def "status-pages delete" [
  statusPageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a single status page by id.
#
# GET /v1/status-pages/{statusPageId}
# operationId: getV1StatuspagesStatuspageid
export def "status-pages get" [
  statusPageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<name: string, description: string, url: string, customDomain: string, themeColors: record<light: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>, dark: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>>, logo: string, redirectTo: string, favicon: string, defaultTheme: string, cards: table<id: string, name: string, services: list, created_at: string, updated_at: string>, id: string, whiteLabel: bool, isPrivate: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing status page.
#
# PUT /v1/status-pages/{statusPageId}
# operationId: putV1StatuspagesStatuspageid
# --themeColors shape: {light: record, dark: record}
# --cards item shape: {id?: string, statusPageId?: string, name: string, services?: list}
export def "status-pages put" [
  statusPageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string
  --description: string # nullable
  --body-url: string
  --customDomain: string # A custom user domain, e.g. "status.example.com". See the docs on updating your DNS and SSL usage. (nullable)
  --themeColors: record # nullable — shape: {light: record, dark: record}
  --logo: string # nullable
  --redirectTo: string # nullable
  --favicon: string # nullable
  --defaultTheme: string@defaultTheme-completer # default: AUTO
  cards: list # item shape: {id?: string, statusPageId?: string, name: string, services?: list}
]: any -> record<name: string, description: string, url: string, customDomain: string, themeColors: record<light: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>, dark: record<bodyBackgroundColor: string, headerBackgroundColor: string, headerFontColor: string, titleFontColor: string, bodyFontColor: string, bodyFontColorMuted: string, navigationFontColor: string, linkFontColor: string, cardBackgroundColor: string, borderColor: string, primaryButtonBackgroundColor: string, primaryButtonFontColor: string>>, logo: string, redirectTo: string, favicon: string, defaultTheme: string, cards: table<id: string, name: string, services: list, created_at: string, updated_at: string>, id: string, whiteLabel: bool, isPrivate: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)")
  let body = {name: $name, description: $description, url: $body_url, customDomain: $customDomain, themeColors: $themeColors, logo: $logo, redirectTo: $redirectTo, favicon: $favicon, defaultTheme: $defaultTheme, cards: $cards} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all subscriptions for a specific status page
#
# GET /v1/status-pages/{statusPageId}/subscriptions
# operationId: getV1StatuspagesStatuspageidSubscriptions
export def "status-pages-subscriptions get" [
  statusPageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, type: string, address: string, status: string, created_at: string, updated_at: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)/subscriptions")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Bulk create subscriptions for a specific status page
#
# POST /v1/status-pages/{statusPageId}/subscriptions/bulk
# operationId: postV1StatuspagesStatuspageidSubscriptionsBulk
# --subscriptions item shape: {type: "EMAIL", config: string}
export def "status-pages-subscriptions-bulk post" [
  statusPageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  subscriptions: list # The list of subscriptions to create (max 100). — item shape: {type: "EMAIL", config: string}
]: any -> record<created: float, skipped: float, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)/subscriptions/bulk")
  let body = {subscriptions: $subscriptions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete a subscription belonging to a specific status page
#
# DELETE /v1/status-pages/{statusPageId}/subscriptions/{subscriptionId}
# operationId: deleteV1StatuspagesStatuspageidSubscriptionsSubscriptionid
export def "status-pages-subscriptions delete" [
  statusPageId: string
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/status-pages/($statusPageId)/subscriptions/($subscriptionId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all test session error groups in your account.
#
# GET /v1/test-session-error-groups
# operationId: getV1Testsessionerrorgroups
export def "test-session-error-groups list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results. (default: 10)
  --page: float # Page number. (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, projectId: string, environments: list<string>, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, pwtMetadata: list<record>, rootCauseAnalyses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/test-session-error-groups" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all test session error groups for a specific project.
#
# GET /v1/test-session-error-groups/projects/{projectId}
# operationId: getV1TestsessionerrorgroupsProjectsProjectid
export def "test-session-error-groups-projects get" [
  projectId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<id: string, projectId: string, environments: list<string>, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, pwtMetadata: list<record>, rootCauseAnalyses: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-session-error-groups/projects/($projectId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve one test session error group.
#
# GET /v1/test-session-error-groups/{id}
# operationId: getV1TestsessionerrorgroupsId
export def "test-session-error-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: string, projectId: string, environments: list<string>, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, pwtMetadata: table<projectName: string, specId: string, testFile: string, testTitle: string, suitePath: list>, rootCauseAnalyses: table<id: string, created_at: string, analysis: any, provider: string, model: string, durationMs: float, userContext: any>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-session-error-groups/($id)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update a test session error group. Mainly used for archiving test session error groups.
#
# PATCH /v1/test-session-error-groups/{id}
# operationId: patchV1TestsessionerrorgroupsId
export def "test-session-error-groups patch" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --archiveForEver: string@bool-completer
  --archivedUntilNextEvent: string@bool-completer
]: any -> record<id: string, projectId: string, environments: list<string>, errorHash: string, rawErrorMessage: string, cleanedErrorMessage: string, firstSeen: string, lastSeen: string, archivedUntilNextEvent: bool, pwtMetadata: table<projectName: string, specId: string, testFile: string, testTitle: string, suitePath: list>, rootCauseAnalyses: table<id: string, created_at: string, analysis: any, provider: string, model: string, durationMs: float, userContext: any>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-session-error-groups/($id)")
  let body = {archiveForEver: $archiveForEver, archivedUntilNextEvent: $archivedUntilNextEvent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# List test sessions
#
# GET /v1/test-sessions
# operationId: getV1Testsessions
export def "test-sessions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: float # Only include test sessions created at or after this Unix timestamp.
  --qp-to: float # Only include test sessions created before this Unix timestamp.
  --limit: int # Maximum number of test sessions to return. (nullable, default: 20)
  --statuses: list # Filter by test session status. (default: [FAILED, PASSED, RUNNING, CANCELLED])
  --branches: list # Filter by Git branch name. (default: [])
  --users: list # Filter by commit owner or invoking user ID. (default: [])
  --providers: list # Filter by test session provider. (default: [])
  --noUsers: string@bool-completer # Include sessions with no commit owner and no invoking user. (default: false)
  --nextId: string # Opaque cursor returned from a previous list response.
  --textSearch: string # Search test session text fields.
  --errorGroupId: string # Filter by test-session error group ID. (nullable)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<length: int, entries: table<id: string, accountId: string, projectId: string, name: string, provider: string, running: list, passed: list, failed: list, cancelled: list, status: string, region: string, privateLocationId: string, invoker: record, repoUrl: string, commitId: string, commitOwner: string, commitMessage: string, branchName: string, environment: string, startedAt: string, stoppedAt: string, created_at: string, updated_at: string>, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "statuses" $statuses "multi") (serialize-qp "branches" $branches "multi") (serialize-qp "users" $users "multi") (serialize-qp "providers" $providers "multi") (serialize-qp "noUsers" $noUsers "scalar") (serialize-qp "nextId" $nextId "scalar") (serialize-qp "textSearch" $textSearch "scalar") (serialize-qp "errorGroupId" $errorGroupId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/test-sessions" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a new test session
#
# POST /v1/test-sessions/trigger
# operationId: postV1TestsessionsTrigger
# --target shape: {matchTags?: list, checkId?: list, allowDeactivated?: bool}
# --metadata shape: {environment?: string, repoUrl?: string, commitId?: string, commitOwner?: string, commitMessage?: string, branchName?: string}
export def "test-sessions-trigger post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the test session.
  runLocation: string # A public region code or private location slug name.
  --target: record # shape: {matchTags?: list, checkId?: list, allowDeactivated?: bool}
  --environmentVariables: list
  --retryStrategy: any
  --refreshCache: string@bool-completer # Skip existing caches and install dependencies from scratch. (default: false)
  --metadata: record # shape: {environment?: string, repoUrl?: string, commitId?: string, commitOwner?: string, commitMessage?: string, branchName?: string}
]: any -> record<testSessionId: string, testSessionLink: string, name: string, status: string, errorGroupIds: list<string>, startedAt: string, stoppedAt: string, timeElapsed: float, metadata: record<environment: string, repoUrl: string, commitId: string, commitOwner: string, commitMessage: string, branchName: string>, results: table<testSessionResultId: string, testSessionResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, errorGroupIds: list, resultType: string, status: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/test-sessions/trigger")
  let body = {name: $name, runLocation: $runLocation, target: $target, environmentVariables: $environmentVariables, retryStrategy: $retryStrategy, refreshCache: $refreshCache, metadata: $metadata} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a test session
#
# GET /v1/test-sessions/{testSessionId}
# operationId: getV1TestsessionsTestsessionid
export def "test-sessions get" [
  testSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<testSessionId: string, testSessionLink: string, name: string, status: string, errorGroupIds: list<string>, startedAt: string, stoppedAt: string, timeElapsed: float, metadata: record<environment: string, repoUrl: string, commitId: string, commitOwner: string, commitMessage: string, branchName: string>, results: table<testSessionResultId: string, testSessionResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, errorGroupIds: list, resultType: string, status: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-sessions/($testSessionId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Cancel a test session
#
# POST /v1/test-sessions/{testSessionId}/cancel
# operationId: postV1TestsessionsTestsessionidCancel
export def "test-sessions-cancel post" [
  testSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --sequenceId: list # Subset of sequence IDs to cancel. Omit to cancel all in-progress sequences.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-sessions/($testSessionId)/cancel")
  let body = {sequenceId: $sequenceId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Await the completion of a test session
#
# GET /v1/test-sessions/{testSessionId}/completion
# operationId: getV1TestsessionsTestsessionidCompletion
export def "test-sessions-completion get" [
  testSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxWaitSeconds: float # Maximum time to wait for completion before returning a retryable timeout response.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<testSessionId: string, testSessionLink: string, name: string, status: string, errorGroupIds: list<string>, startedAt: string, stoppedAt: string, timeElapsed: float, metadata: record<environment: string, repoUrl: string, commitId: string, commitOwner: string, commitMessage: string, branchName: string>, results: table<testSessionResultId: string, testSessionResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, errorGroupIds: list, resultType: string, status: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxWaitSeconds" $maxWaitSeconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/test-sessions/($testSessionId)/completion" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a test session result
#
# GET /v1/test-sessions/{testSessionId}/results/{testSessionResultId}
# operationId: getV1TestsessionsTestsessionidResultsTestsessionresultid
export def "test-sessions-results get" [
  testSessionId: string
  testSessionResultId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<testSessionResultId: string, testSessionResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, errorGroupIds: list<string>, resultType: string, status: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool, id: string, privateLocationId: string, filePath: string, isCancelled: bool, overMaxResponseTime: bool, responseTime: float, attempts: int, sequenceId: string, scheduleError: string, traceId: string, startedAt: string, stoppedAt: string, created_at: string, updated_at: string, apiCheckResult: record<assertions: list<record>, request: record, response: record, requestError: string, jobLog: any, jobAssets: list<string>, pcapDataUrl: string>, browserCheckResult: record<type: string, traceSummary: record, pages: list<record>, errors: list<any>, endTime: float, startTime: float, runtimeVersion: string, jobLog: any, jobAssets: list<string>, pcapDataUrl: string, playwrightTestVideos: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, multiStepCheckResult: record<errors: list<any>, endTime: float, startTime: float, runtimeVersion: string, jobLog: any, jobAssets: list<string>, pcapDataUrl: string, playwrightTestVideos: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, playwrightCheckResult: record<errors: list<any>, playwrightTraceFiles: list<record>, jobLog: any, jobAssets: list<string>, pcapDataUrl: string, playwrightTestVideos: list<string>, playwrightTestTraces: list<string>, playwrightTestJsonReportFile: string>, agenticCheckResult: record<summary: string, prompt: string, assertions: list<record>, suggestions: list<record>, steps: list<record>, errors: list<any>, artifactManifest: record, jobLog: any, jobAssets: list<string>, pcapDataUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/test-sessions/($testSessionId)/results/($testSessionResultId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve a normalized asset manifest for a test-session result
#
# GET /v1/test-sessions/{testSessionId}/results/{testSessionResultId}/assets
# operationId: getV1TestsessionsTestsessionidResultsTestsessionresultidAssets
export def "test-sessions-results-assets get" [
  testSessionId: string
  testSessionResultId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --type: list # Filter assets by normalized asset type. Repeat the query parameter to include multiple types.
  --name: string # Glob pattern matched case-insensitively against the asset name and archive entry path. Empty patterns are ignored.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<assets: table<type: string, name: string, url: string, contentType: string, source: record, archive: record>, truncated: bool, entriesReturned: int, entriesTotal: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "type" $type "multi") (serialize-qp "name" $name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1/test-sessions/($testSessionId)/results/($testSessionResultId)/assets" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the check group trigger
#
# DELETE /v1/triggers/check-groups/{groupId}
# DEPRECATED
# operationId: deleteV1TriggersCheckgroupsGroupid
@deprecated
export def "triggers-check-groups delete" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/check-groups/($groupId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the check group trigger
#
# GET /v1/triggers/check-groups/{groupId}
# DEPRECATED
# operationId: getV1TriggersCheckgroupsGroupid
@deprecated
export def "triggers-check-groups get" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, token: string, created_at: string, called_at: string, updated_at: string, groupId: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/check-groups/($groupId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the check group trigger
#
# POST /v1/triggers/check-groups/{groupId}
# DEPRECATED
# operationId: postV1TriggersCheckgroupsGroupid
@deprecated
export def "triggers-check-groups post" [
  groupId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, token: string, created_at: string, called_at: string, updated_at: string, groupId: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/check-groups/($groupId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the check trigger
#
# DELETE /v1/triggers/checks/{checkId}
# DEPRECATED
# operationId: deleteV1TriggersChecksCheckid
@deprecated
export def "triggers-checks delete" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/checks/($checkId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the check trigger
#
# GET /v1/triggers/checks/{checkId}
# DEPRECATED
# operationId: getV1TriggersChecksCheckid
@deprecated
export def "triggers-checks get" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, token: string, created_at: string, called_at: string, updated_at: string, checkId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/checks/($checkId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create the check trigger
#
# POST /v1/triggers/checks/{checkId}
# DEPRECATED
# operationId: postV1TriggersChecksCheckid
@deprecated
export def "triggers-checks post" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<id: float, token: string, created_at: string, called_at: string, updated_at: string, checkId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/triggers/checks/($checkId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# List all environment variables
#
# GET /v1/variables
# operationId: getV1Variables
export def "variables list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results (default: 10)
  --page: float # Page number (default: 1)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> table<key: string, value: string, locked: bool, secret: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "page" $page "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v1/variables" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create an environment variable
#
# POST /v1/variables
# operationId: postV1Variables
export def "variables post" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  key: string # The key of the environment variable (this value cannot be changed). (e.g. API_KEY)
  value: string
  --locked: string@bool-completer # Used only in the UI to hide the value like a password. (default: false)
  --secret: string@bool-completer # Set an environment variable as secret. Once set, its value cannot be unlocked. (default: false)
]: any -> record<key: string, value: string, locked: bool, secret: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v1/variables")
  let body = {key: $key, value: $value, locked: $locked, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete an environment variable
#
# DELETE /v1/variables/{key}
# operationId: deleteV1VariablesKey
export def "variables delete" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/variables/($key)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve an environment variable
#
# GET /v1/variables/{key}
# operationId: getV1VariablesKey
export def "variables get" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<key: string, value: string, locked: bool, secret: bool> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/variables/($key)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an environment variable
#
# PUT /v1/variables/{key}
# operationId: putV1VariablesKey
export def "variables put" [
  key: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --body-key: string # The key of the environment variable (this value cannot be changed). (e.g. API_KEY)
  value: string # The value of the environment variable. (e.g. bAxD7biGCZL6K60Q)
  --locked: string@bool-completer # Used only in the UI to hide the value like a password. (default: false)
  --secret: string@bool-completer # Set an environment variable as secret. Once set, its value cannot be unlocked. (default: false)
]: any -> record<key: string, value: string, locked: bool, secret: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v1/variables/($key)")
  let body = {key: $body_key, value: $value, locked: $locked, secret: $secret} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create a check group (V2)
#
# POST /v2/check-groups
# operationId: postV2Checkgroups
# --apiCheckDefaults shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
# --environmentVariables item shape: {key?: string, value: string, locked?: bool, secret?: bool}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", runBasedEscalation?: record, timeBasedEscalation?: record, reminders?: record, parallelRunFailureThreshold?: record}
export def "check-groups post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check group. (e.g. Check group)
  --activated: string@bool-completer # Determines if the checks in the group are running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check in this group fails and/or recovers. (default: false)
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --locations: list # An array of one or more data center locations where to run the checks. (e.g. [us-east-1, eu-central-1])
  --concurrency: float # Determines how many checks are invoked concurrently when triggering a check group from CI/CD or through the API. (default: 3)
  --apiCheckDefaults: record # default: {}, e.g. {url: https://api.example.com/v1, headers: [{key: Cache-Control, value: no-store}], queryParameters: [{key: Page, value: 1}], assertions: [{source: STATUS_CODE, comparison: NOT_EMPTY, target: 200}], basicAuth: {username: admin, password: abc12345}} — shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --browserCheckDefaults: string
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute checks in this group. (nullable)
  --environmentVariables: list # nullable — item shape: {key?: string, value: string, locked?: bool, secret?: bool}
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check in this group. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check in this group. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase of an API check in this group. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase of an API check in this group. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the checks. (nullable, e.g. [data-center-eu])
  --runParallel: string@bool-completer # When true, the checks in the group will run in parallel in all selected locations. (nullable)
  --alertSettings: record # nullable — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", runBasedEscalation?: record, timeBasedEscalation?: record, reminders?: record, parallelRunFailureThreshold?: record}
  --retryStrategy: any # Either a retry strategy object or the literal string "FALLBACK". (default: FALLBACK)
  --useGlobalAlertSettings: string@bool-completer # When true, the checks in the group will use the alert settings that are configured on the account (nullable)
  --doubleCheck: string@bool-completer # default: false
]: any -> record<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, browserCheckDefaults: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/check-groups" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, tags: $tags, locations: $locations, concurrency: $concurrency, apiCheckDefaults: $apiCheckDefaults, browserCheckDefaults: $browserCheckDefaults, runtimeId: $runtimeId, environmentVariables: $environmentVariables, alertChannelSubscriptions: $alertChannelSubscriptions, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, privateLocations: $privateLocations, runParallel: $runParallel, alertSettings: $alertSettings, retryStrategy: $retryStrategy, useGlobalAlertSettings: $useGlobalAlertSettings, doubleCheck: $doubleCheck} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Update a check group (V2)
#
# PUT /v2/check-groups/{id}
# operationId: putV2CheckgroupsId
# --apiCheckDefaults shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
# --environmentVariables item shape: {key?: string, value: string, locked?: bool, secret?: bool}
# --alertChannelSubscriptions item shape: {alertChannelId: float, activated: bool}
# --alertSettings shape: {escalationType?: "RUN_BASED"|"TIME_BASED", runBasedEscalation?: record, timeBasedEscalation?: record, reminders?: record, parallelRunFailureThreshold?: record}
export def "check-groups put-by-id-1" [
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --autoAssignAlerts: string@bool-completer # Determines whether a new check will automatically be added as a subscriber to all existing alert channels when it gets created. (default: true)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  name: string # The name of the check group. (e.g. Check group)
  --activated: string@bool-completer # Determines if the checks in the group are running or not. (default: true)
  --muted: string@bool-completer # Determines if any notifications will be send out when a check in this group fails and/or recovers. (default: false)
  --tags: list # Tags for organizing and filtering checks. (e.g. [production])
  --locations: list # An array of one or more data center locations where to run the checks. (e.g. [us-east-1, eu-central-1])
  --concurrency: float # Determines how many checks are invoked concurrently when triggering a check group from CI/CD or through the API. (default: 3)
  --apiCheckDefaults: record # default: {}, e.g. {url: https://api.example.com/v1, headers: [{key: Cache-Control, value: no-store}], queryParameters: [{key: Page, value: 1}], assertions: [{source: STATUS_CODE, comparison: NOT_EMPTY, target: 200}], basicAuth: {username: admin, password: abc12345}} — shape: {url?: string, headers?: list, queryParameters?: list, assertions?: list, basicAuth?: record}
  --browserCheckDefaults: string
  --runtimeId: string@runtimeId-completer # The runtime version, i.e. fixed set of runtime dependencies, used to execute checks in this group. (nullable)
  --environmentVariables: list # nullable — item shape: {key?: string, value: string, locked?: bool, secret?: bool}
  --alertChannelSubscriptions: list # List of alert channel subscriptions. (e.g. []) — item shape: {alertChannelId: float, activated: bool}
  --setupSnippetId: float # An ID reference to a snippet to use in the setup phase of an API check in this group. (nullable)
  --tearDownSnippetId: float # An ID reference to a snippet to use in the teardown phase of an API check in this group. (nullable)
  --localSetupScript: string # A valid piece of Node.js code to run in the setup phase of an API check in this group. (nullable)
  --localTearDownScript: string # A valid piece of Node.js code to run in the teardown phase of an API check in this group. (nullable)
  --privateLocations: list # An array of one or more private locations where to run the checks. (nullable, e.g. [data-center-eu])
  --runParallel: string@bool-completer # When true, the checks in the group will run in parallel in all selected locations. (nullable)
  --alertSettings: record # nullable — shape: {escalationType?: "RUN_BASED"|"TIME_BASED", runBasedEscalation?: record, timeBasedEscalation?: record, reminders?: record, parallelRunFailureThreshold?: record}
  --retryStrategy: any # Either a retry strategy object or the literal string "FALLBACK". (default: FALLBACK)
  --useGlobalAlertSettings: string@bool-completer # When true, the checks in the group will use the alert settings that are configured on the account (nullable)
  --doubleCheck: string@bool-completer # default: false
]: any -> record<id: float, name: string, activated: bool, muted: bool, tags: list<string>, locations: list<string>, concurrency: float, apiCheckDefaults: record<url: string, headers: list<record>, queryParameters: list<record>, assertions: list<record>, basicAuth: record<username: string, password: string>>, browserCheckDefaults: string, environmentVariables: table<key: string, value: string, locked: bool, secret: bool>, doubleCheck: bool, useGlobalAlertSettings: bool, alertSettings: record<escalationType: string, reminders: record<amount: float, interval: float>, sslCertificates: record<enabled: bool, alertThreshold: int>, runBasedEscalation: record<failedRunThreshold: float>, timeBasedEscalation: record<minutesFailingThreshold: float>, parallelRunFailureThreshold: record<enabled: bool, percentage: float>>, alertChannelSubscriptions: table<alertChannelId: float, activated: bool>, setupSnippetId: float, tearDownSnippetId: float, localSetupScript: string, localTearDownScript: string, runtimeId: string, privateLocations: list<string>, retryStrategy: any, created_at: string, updated_at: string, runParallel: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "autoAssignAlerts" $autoAssignAlerts "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/check-groups/($id)" $qp)
  let body = {name: $name, activated: $activated, muted: $muted, tags: $tags, locations: $locations, concurrency: $concurrency, apiCheckDefaults: $apiCheckDefaults, browserCheckDefaults: $browserCheckDefaults, runtimeId: $runtimeId, environmentVariables: $environmentVariables, alertChannelSubscriptions: $alertChannelSubscriptions, setupSnippetId: $setupSnippetId, tearDownSnippetId: $tearDownSnippetId, localSetupScript: $localSetupScript, localTearDownScript: $localTearDownScript, privateLocations: $privateLocations, runParallel: $runParallel, alertSettings: $alertSettings, retryStrategy: $retryStrategy, useGlobalAlertSettings: $useGlobalAlertSettings, doubleCheck: $doubleCheck} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Lists all check results
#
# GET /v2/check-results/{checkId}
# operationId: getV2CheckresultsCheckid
export def "check-results get-by-checkId-1" [
  checkId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --limit: int # Limit the number of results to fetch (default 10) (default: 10)
  --nextId: string # Cursor parameter to fetch the next page of results. The "nextId" parameter is returned in the response of the previous request. If a response includes a "nextId" parameter set to "null", there are no more results to fetch.
  --qp-from: string # Select records up from this UNIX timestamp (>= date). (format: date)
  --qp-to: string # Optional. Select records up to this UNIX timestamp (< date). (format: date)
  --location: string@location-completer # Provide a data center location, e.g. "eu-west-1" to filter by location
  --checkType: string@checkType-completer # The type of the check
  --hasFailures: string@bool-completer # Check result has one or more failures
  --resultType: string@resultType-completer # The check result type (FINAL,ATTEMPT,ALL) (default: FINAL)
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<length: float, entries: table<id: string, name: string, checkId: string, hasFailures: bool, hasErrors: bool, isDegraded: bool, isCancelled: bool, overMaxResponseTime: bool, runLocation: string, startedAt: string, stoppedAt: string, created_at: string, responseTime: float, apiCheckResult: record, browserCheckResult: record, multiStepCheckResult: record, agenticCheckResult: record, playwrightCheckResult: record, checkRunId: float, attempts: float, resultType: string, sequenceId: string, traceId: string, errorGroupIds: list>, nextId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "limit" $limit "scalar") (serialize-qp "nextId" $nextId "scalar") (serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "location" $location "scalar") (serialize-qp "checkType" $checkType "scalar") (serialize-qp "hasFailures" $hasFailures "scalar") (serialize-qp "resultType" $resultType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/check-results/($checkId)" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a new check session
#
# POST /v2/check-sessions/trigger
# operationId: postV2ChecksessionsTrigger
# --target shape: {matchTags?: list, checkId?: list}
export def "check-sessions-trigger post-1" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
  --target: record # Optional filters selecting which checks to trigger. — shape: {matchTags?: list, checkId?: list}
  --refreshCache: string@bool-completer # Refresh the selected checks cache before triggering the sessions. (default: false)
]: any -> record<sessions: table<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list, runSource: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/check-sessions/trigger")
  let body = {target: $target, refreshCache: $refreshCache} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a check session
#
# GET /v2/check-sessions/{checkSessionId}
# operationId: getV2ChecksessionsChecksessionid
export def "check-sessions get-by-checkSessionId-1" [
  checkSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list<string>, runSource: string, results: table<checkResultId: string, checkResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, resultType: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool, isCancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/check-sessions/($checkSessionId)")
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Await the completion of a check session
#
# GET /v2/check-sessions/{checkSessionId}/completion
# operationId: getV2ChecksessionsChecksessionidCompletion
export def "check-sessions-completion get-by-checkSessionId-1" [
  checkSessionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --maxWaitSeconds: int # Maximum time to wait for completion before returning a retryable timeout response.
  --x-checkly-account: string # Your Checkly account ID, you can find it at https://app.checklyhq.com/settings/account/general
]: nothing -> record<checkSessionId: string, checkSessionLink: string, checkId: string, checkType: string, name: string, status: string, startedAt: string, stoppedAt: string, timeElapsed: float, runLocations: list<string>, runSource: string, results: table<checkResultId: string, checkResultLink: string, checkId: string, checkType: string, name: string, runLocation: string, resultType: string, hasErrors: bool, hasFailures: bool, isDegraded: bool, aborted: bool, isCancelled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "maxWaitSeconds" $maxWaitSeconds "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/check-sessions/($checkSessionId)/completion" $qp)
  let extra_headers = {"x-checkly-account": $x_checkly_account} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
