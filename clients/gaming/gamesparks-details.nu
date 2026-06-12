# Auto-generated client for GameSparks Game Details API vv2
# Source: https://api.apis.guru/v2/specs/gamesparks.net/game-details/v2/openapi.json
# Auth: --token flag or $env.GAMESPARKS_GAME_DETAILS_API_TOKEN

const BASE_URL = "http://localhost//config2.gamesparks.net"
const DEFAULT_AUTH = "accesstoken"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o GAMESPARKS_GAME_DETAILS_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "accesstoken" => { {headers: {accessToken: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "jwt" => { {headers: {jwt: $token_val}, query: ""} }
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

def base-url-completer [] { ["http://localhost//config2.gamesparks.net"] }
def auth-scheme-completer [] { ["accesstoken" "basic" "jwt"] }

# Completers for enum parameters
def stage-completer [] { ["LIVE" "PREVIEW"] }
def dataType-completer [] { ["activeDevices" "activeLocations" "activeUsers" "averageBandwidthPerUser" "averageDauOverMau" "averageJsExecutionTime" "averageRequestsPerUser" "averageResponseTime" "averageResponseTimePerType" "connectedUsers" "customAnalyticTotal" "customAnalyticUser" "scriptLogLevelsCount" "sessionAnalytic" "sessionAnalyticTotal" "storagePerUser" "timedAnalyticTotal"] }
def precision-completer [] { ["DAILY" "HOURLY" "MONTHLY"] }
def queryName-completer [] { ["activeUsersNow" "averageDailyActiveUsers" "averageSessionDuration" "dailyActiveUsers" "lastMonthlyActiveUsers" "monthlyActiveUsers"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "restv2-game-regions list" } } | get name | first)
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

# getRegionOptions
#
# GET /restv2/game/regions
# operationId: getRegionOptionsUsingGET
export def "restv2-game-regions list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/game/regions")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the results of executed query defined by the parameters passed in
#
# GET /restv2/game/{apiKey}/admin/analytics
# operationId: getAnalyticsDataUsingGET
export def "restv2-game-admin-analytics get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --dataType: string@dataType-completer # dataType
  --precision: string@precision-completer # precision
  --startDate: string # yyyy-MM-dd (format: date)
  --endDate: string # yyyy-MM-dd (format: date)
  --keys: string # the keys to select. For example "ReturningUsers", "NewUsers", etc
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "dataType" $dataType "scalar") (serialize-qp "precision" $precision "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar") (serialize-qp "keys" $keys "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/analytics" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the count of executed query
#
# GET /restv2/game/{apiKey}/admin/analytics/count
# operationId: getDataCountUsingGET
export def "restv2-game-admin-analytics-count get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --queryName: string@queryName-completer # queryName
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "queryName" $queryName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/analytics/count" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns the percentage of user retention over the last 30 days
#
# GET /restv2/game/{apiKey}/admin/analytics/rollingRetention
# operationId: getRetentionUsingGET
export def "restv2-game-admin-analytics-rolling-retention get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stage" $stage "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/analytics/rollingRetention" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves the Billing Details
#
# GET /restv2/game/{apiKey}/admin/billingDetails
# operationId: getBillingDetails
export def "restv2-game-admin-billing-details get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/billingDetails")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the Billing Details
#
# PUT /restv2/game/{apiKey}/admin/billingDetails
# operationId: putBillingDetails
export def "restv2-game-admin-billing-details put" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  building: string
  city: string
  companyName: string
  country: string
  email1: string
  --email2: string
  --email3: string
  firstName1: string
  --firstName2: string
  --firstName3: string
  lastName1: string
  --lastName2: string
  --lastName3: string
  postcode: string
  --state: string
  street: string
  --taxNumber: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/billingDetails")
  let body = {building: $building, city: $city, companyName: $companyName, country: $country, email1: $email1, email2: $email2, email3: $email3, firstName1: $firstName1, firstName2: $firstName2, firstName3: $firstName3, lastName1: $lastName1, lastName2: $lastName2, lastName3: $lastName3, postcode: $postcode, state: $state, street: $street, taxNumber: $taxNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getGameSummary
#
# GET /restv2/game/{apiKey}/admin/notifications/summary
# operationId: getGameSummaryUsingGET
export def "restv2-game-admin-notifications-summary get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --stage: string@stage-completer # stage
  --startDate: string # yyyy-MM-dd (format: date)
  --endDate: string # yyyy-MM-dd (format: date)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "stage" $stage "scalar") (serialize-qp "startDate" $startDate "scalar") (serialize-qp "endDate" $endDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/notifications/summary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# testPushAmazonNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/amazon
# operationId: testPushAmazonNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-amazon testPushAmazonNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/amazon")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testPushAppleDevNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/development
# operationId: testPushAppleDevNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-apple-development testPushAppleDevNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/apple/development")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testPushAppleProdNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/apple/production
# operationId: testPushAppleProdNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-apple-production testPushAppleProdNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/apple/production")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testPushGoogleNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/google
# operationId: testPushGoogleNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-google testPushGoogleNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/google")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testWindows8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windows8
# operationId: testWindows8NotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-microsoft-windows8 testWindows8NotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/microsoft/windows8")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testWindowsPhone8Notifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/microsoft/windowsPhone8
# operationId: testWindowsPhone8NotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-microsoft-windows-phone8 testWindowsPhone8NotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/microsoft/windowsPhone8")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testViberIntegrationNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/integration
# operationId: testViberIntegrationNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-viber-integration testViberIntegrationNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/viber/integration")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# testViberProductionNotifications
#
# POST /restv2/game/{apiKey}/admin/pushNotifications/test/viber/production
# operationId: testViberProductionNotificationsUsingPOST
export def "restv2-game-admin-push-notifications-test-viber-production testViberProductionNotificationsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customJson: string
  --messageId: string
  --pushId: string
  --subtitle: string
  --summary: string
  --title: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/pushNotifications/test/viber/production")
  let body = {customJson: $customJson, messageId: $messageId, pushId: $pushId, subtitle: $subtitle, summary: $summary, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getScriptDifferences
#
# GET /restv2/game/{apiKey}/admin/scripts/differences/{snapshotId1}/{snapshotId2}
# operationId: getScriptDifferencesUsingGET
export def "restv2-game-admin-scripts-differences get" [
  apiKey: string
  snapshotId1: string
  snapshotId2: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/differences/($snapshotId1)/($snapshotId2)")
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# exportZip
#
# GET /restv2/game/{apiKey}/admin/scripts/export
# operationId: exportZipUsingGET
export def "restv2-game-admin-scripts-export exportZipUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/export")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# importAccept
#
# POST /restv2/game/{apiKey}/admin/scripts/import/accept
# operationId: importAcceptUsingPOST
export def "restv2-game-admin-scripts-import-accept importAcceptUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-body: string # body
  file: string # file (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "body" $qp_body "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/import/accept" $qp)
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# importZip
#
# POST /restv2/game/{apiKey}/admin/scripts/import/preview
# operationId: importZipUsingPOST
export def "restv2-game-admin-scripts-import-preview importZipUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  file: string # file (format: binary)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/import/preview")
  let body = {file: $file} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "multipart/form-data" $body
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions
# operationId: getScriptVersionsUsingGET_1
export def "restv2-game-admin-scripts-versions get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # pageSize (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/versions" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getScriptVersions
#
# GET /restv2/game/{apiKey}/admin/scripts/versions/{page}
# operationId: getScriptVersionsUsingGET
export def "restv2-game-admin-scripts-versions get" [
  apiKey: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # pageSize (format: int32, default: 100)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/scripts/versions/($page)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSegmentQueryFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters
# operationId: getSegmentQueryFiltersUsingGET
export def "restv2-game-admin-segment-query-filters get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/segmentQueryFilters")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSegmentQueryFiltersConfig
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: getSegmentQueryFiltersConfigUsingGET
export def "restv2-game-admin-segment-query-filters-config get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/segmentQueryFilters/config")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateSegmentQueryFiltersConfig
#
# PUT /restv2/game/{apiKey}/admin/segmentQueryFilters/config
# operationId: updateSegmentQueryFiltersConfigUsingPUT
# --customFilters item shape: {key?: string, name?: string, options?: list, type?: string}
export def "restv2-game-admin-segment-query-filters-config updateSegmentQueryFiltersConfigUsingPUT" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --customFilters: list # item shape: {key?: string, name?: string, options?: list, type?: string}
  --hiddenFilters: list
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/segmentQueryFilters/config")
  let body = {customFilters: $customFilters, hiddenFilters: $hiddenFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getSegmentQueryStandardFilters
#
# GET /restv2/game/{apiKey}/admin/segmentQueryFilters/standardFilters
# operationId: getSegmentQueryStandardFiltersUsingGET
export def "restv2-game-admin-segment-query-filters-standard-filters get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/segmentQueryFilters/standardFilters")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots
# operationId: getSnapshotsUsingGET_1
export def "restv2-game-admin-snapshots get-by-apiKey" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # pageSize (format: int32, default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createSnapshots
#
# POST /restv2/game/{apiKey}/admin/snapshots
# operationId: createSnapshotsUsingPOST
export def "restv2-game-admin-snapshots createSnapshotsUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# getLiveSnapshotId
#
# GET /restv2/game/{apiKey}/admin/snapshots/liveSnapshotId
# operationId: getLiveSnapshotIdUsingGET
export def "restv2-game-admin-snapshots-live-snapshot-id get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/liveSnapshotId")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSnapshots
#
# GET /restv2/game/{apiKey}/admin/snapshots/page/{page}
# operationId: getSnapshotsUsingGET
export def "restv2-game-admin-snapshots-page get" [
  apiKey: string
  page: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageSize: int # pageSize (format: int32, default: 20)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/page/($page)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# revertToSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/revert/to/{snapshotId}
# operationId: revertToSnapshotUsingPOST
export def "restv2-game-admin-snapshots-revert-to revertToSnapshotUsingPOST" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/revert/to/($snapshotId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE_1
export def "restv2-game-admin-snapshots delete-by-apiKey-snapshotId" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSnapshot
#
# GET /restv2/game/{apiKey}/admin/snapshots/{snapshotId}
# operationId: getSnapshotUsingGET
export def "restv2-game-admin-snapshots get" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# copySnapshotToNewGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy
# operationId: copySnapshotToNewGameUsingPOST
export def "restv2-game-admin-snapshots-copy copySnapshotToNewGameUsingPOST" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGameConfig: oneof<nothing, bool> # includeGameConfig (default: true)
  --includeMetadata: oneof<nothing, bool> # includeMetadata (default: true)
  --includeBinaries: oneof<nothing, bool> # includeBinaries (default: true)
  --includeCollaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGameConfig" $includeGameConfig "scalar") (serialize-qp "includeMetadata" $includeMetadata "scalar") (serialize-qp "includeBinaries" $includeBinaries "scalar") (serialize-qp "includeCollaborators" $includeCollaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)/copy" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST_1
export def "restv2-game-admin-snapshots-copy-to copySnapshotToExistingGameUsingPOST-by-apiKey-snapshotId-targetApiKey" [
  apiKey: string
  snapshotId: string
  targetApiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --includeGameConfig: oneof<nothing, bool> # includeGameConfig (default: true)
  --includeMetadata: oneof<nothing, bool> # includeMetadata (default: true)
  --includeBinaries: oneof<nothing, bool> # includeBinaries (default: true)
  --includeCollaborators: oneof<nothing, bool> # includeCollaborators (default: true)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "includeGameConfig" $includeGameConfig "scalar") (serialize-qp "includeMetadata" $includeMetadata "scalar") (serialize-qp "includeBinaries" $includeBinaries "scalar") (serialize-qp "includeCollaborators" $includeCollaborators "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)/copy/to/($targetApiKey)" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST_1
export def "restv2-game-admin-snapshots-publish publishSnapshotUsingPOST-by-apiKey-snapshotId" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)/publish")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# unpublishSnapshot
#
# POST /restv2/game/{apiKey}/admin/snapshots/{snapshotId}/unpublish
# operationId: unpublishSnapshotUsingPOST
export def "restv2-game-admin-snapshots-unpublish unpublishSnapshotUsingPOST" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/snapshots/($snapshotId)/unpublish")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTestHarnessScenarios
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: getTestHarnessScenariosUsingGET
export def "restv2-game-admin-test-harness-scenarios list" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/testHarness/scenarios")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createTestHarnessScenario
#
# POST /restv2/game/{apiKey}/admin/testHarness/scenarios
# operationId: createTestHarnessScenarioUsingPOST
export def "restv2-game-admin-test-harness-scenarios createTestHarnessScenarioUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenarioJson: record
  --scenarioName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/testHarness/scenarios")
  let body = {scenarioJson: $scenarioJson, scenarioName: $scenarioName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteTestHarnessScenario
#
# DELETE /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: deleteTestHarnessScenarioUsingDELETE
export def "restv2-game-admin-test-harness-scenarios delete" [
  apiKey: string
  scenarioName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/testHarness/scenarios/($scenarioName)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getTestHarnessScenario
#
# GET /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: getTestHarnessScenarioUsingGET
export def "restv2-game-admin-test-harness-scenarios get" [
  apiKey: string
  scenarioName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/testHarness/scenarios/($scenarioName)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateTestHarnessScenario
#
# PUT /restv2/game/{apiKey}/admin/testHarness/scenarios/{scenarioName}
# operationId: updateTestHarnessScenarioUsingPUT
export def "restv2-game-admin-test-harness-scenarios updateTestHarnessScenarioUsingPUT" [
  apiKey: string
  scenarioName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --scenarioJson: record
  --body-scenarioName: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/admin/testHarness/scenarios/($scenarioName)")
  let body = {scenarioJson: $scenarioJson, scenarioName: $body_scenarioName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resets the secret of a credential
#
# POST /restv2/game/{apiKey}/config/~credentials/{credentialName}/resetSecret
# operationId: updateCredentialSecretUsingPOST
export def "restv2-game-config-credentials-reset-secret updateCredentialSecretUsingPOST" [
  apiKey: string
  credentialName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/config/~credentials/($credentialName)/resetSecret")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getGamesEndpoints
#
# GET /restv2/game/{apiKey}/endpoints
# operationId: getGamesEndpointsUsingGET
export def "restv2-game-endpoints get" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/endpoints")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getExperiments
#
# GET /restv2/game/{apiKey}/manage/experiments
# operationId: getExperimentsUsingGET
export def "restv2-game-manage-experiments list" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments
# operationId: createExperimentUsingPOST
# --config shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
export def "restv2-game-manage-experiments createExperimentUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --changedFieldsAndInitialValues: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --endDate: string # format: date-time
  --id: int # format: int64
  --measurements: string
  --measurementsEsQuery: string
  --name: string
  --percentHash: string
  --publishedStages: list
  --startDate: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments")
  let body = {active: $active, changedFieldsAndInitialValues: $changedFieldsAndInitialValues, complete: $complete, config: $config, endDate: $endDate, id: $id, measurements: $measurements, measurementsEsQuery: $measurementsEsQuery, name: $name, percentHash: $percentHash, publishedStages: $publishedStages, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteExperiment
#
# DELETE /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: deleteExperimentUsingDELETE
export def "restv2-game-manage-experiments delete" [
  apiKey: string
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
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getExperiment
#
# GET /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: getExperimentUsingGET
export def "restv2-game-manage-experiments get" [
  apiKey: string
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
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments/($id)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateExperiment
#
# PUT /restv2/game/{apiKey}/manage/experiments/{id}
# operationId: updateExperimentUsingPUT
# --config shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
export def "restv2-game-manage-experiments updateExperimentUsingPUT" [
  apiKey: string
  id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --active: oneof<nothing, bool>
  --changedFieldsAndInitialValues: record
  --complete: oneof<nothing, bool>
  --config: record # shape: {playerMongoQuery?: string, playerQuery?: string, variants?: string}
  --endDate: string # format: date-time
  --body-id: int # format: int64
  --measurements: string
  --measurementsEsQuery: string
  --name: string
  --percentHash: string
  --publishedStages: list
  --startDate: string # format: date-time
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments/($id)")
  let body = {active: $active, changedFieldsAndInitialValues: $changedFieldsAndInitialValues, complete: $complete, config: $config, endDate: $endDate, id: $body_id, measurements: $measurements, measurementsEsQuery: $measurementsEsQuery, name: $name, percentHash: $percentHash, publishedStages: $publishedStages, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# doActionExperiment
#
# POST /restv2/game/{apiKey}/manage/experiments/{id}/{action}
# operationId: doActionExperimentUsingPOST
export def "restv2-game-manage-experiments doActionExperimentUsingPOST" [
  apiKey: string
  id: int
  action: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/experiments/($id)/($action)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# listQueries
#
# GET /restv2/game/{apiKey}/manage/queries
# operationId: listQueriesUsingGET
export def "restv2-game-manage-queries listQueriesUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/queries")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createQuery
#
# POST /restv2/game/{apiKey}/manage/queries
# operationId: createQueryUsingPOST
export def "restv2-game-manage-queries createQueryUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --esRules: string
  --name: string
  --qbRules: string
  --shortCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/queries")
  let body = {esRules: $esRules, name: $name, qbRules: $qbRules, shortCode: $shortCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteQuery
#
# DELETE /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: deleteQueryUsingDELETE
export def "restv2-game-manage-queries delete" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/queries/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getQuery
#
# GET /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: getQueryUsingGET
export def "restv2-game-manage-queries get" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/queries/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateQuery
#
# PUT /restv2/game/{apiKey}/manage/queries/{shortCode}
# operationId: updateQueryUsingPUT
export def "restv2-game-manage-queries updateQueryUsingPUT" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --esRules: string
  --name: string
  --qbRules: string
  --body-shortCode: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/queries/($shortCode)")
  let body = {esRules: $esRules, name: $name, qbRules: $qbRules, shortCode: $body_shortCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# listScreens
#
# GET /restv2/game/{apiKey}/manage/screens
# operationId: listScreensUsingGET
export def "restv2-game-manage-screens listScreensUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createScreen
#
# POST /restv2/game/{apiKey}/manage/screens
# operationId: createScreenUsingPOST
export def "restv2-game-manage-screens createScreenUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list
  --name: string
  --shortCode: string
  --template: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens")
  let body = {groups: $groups, name: $name, shortCode: $shortCode, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# listExecutableScreens
#
# GET /restv2/game/{apiKey}/manage/screens/executable
# operationId: listExecutableScreensUsingGET
export def "restv2-game-manage-screens-executable listExecutableScreensUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens/executable")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# deleteScreen
#
# DELETE /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: deleteScreenUsingDELETE
export def "restv2-game-manage-screens delete" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getScreen
#
# GET /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: getScreenUsingGET
export def "restv2-game-manage-screens get" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateScreen
#
# PUT /restv2/game/{apiKey}/manage/screens/{shortCode}
# operationId: updateScreenUsingPUT
export def "restv2-game-manage-screens updateScreenUsingPUT" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list
  --name: string
  --body-shortCode: string
  --template: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/screens/($shortCode)")
  let body = {groups: $groups, name: $name, shortCode: $body_shortCode, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# listSnapshots
#
# GET /restv2/game/{apiKey}/manage/snapshots
# operationId: listSnapshotsUsingGET
export def "restv2-game-manage-snapshots listSnapshotsUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots
# operationId: createSnapshotUsingPOST
export def "restv2-game-manage-snapshots createSnapshotUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --description: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots")
  let body = {description: $description} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteSnapshot
#
# DELETE /restv2/game/{apiKey}/manage/snapshots/{snapshotId}
# operationId: deleteSnapshotUsingDELETE
export def "restv2-game-manage-snapshots delete" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots/($snapshotId)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# copySnapshotToExistingGame
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/copy/to/{targetApiKey}
# operationId: copySnapshotToExistingGameUsingPOST
export def "restv2-game-manage-snapshots-copy-to copySnapshotToExistingGameUsingPOST" [
  apiKey: string
  snapshotId: string
  targetApiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots/($snapshotId)/copy/to/($targetApiKey)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# publishSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/publish
# operationId: publishSnapshotUsingPOST
export def "restv2-game-manage-snapshots-publish publishSnapshotUsingPOST" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots/($snapshotId)/publish")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# revertSnapshot
#
# POST /restv2/game/{apiKey}/manage/snapshots/{snapshotId}/revert
# operationId: revertSnapshotUsingPOST
export def "restv2-game-manage-snapshots-revert revertSnapshotUsingPOST" [
  apiKey: string
  snapshotId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snapshots/($snapshotId)/revert")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# listSnippets
#
# GET /restv2/game/{apiKey}/manage/snippets
# operationId: listSnippetsUsingGET
export def "restv2-game-manage-snippets listSnippetsUsingGET" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snippets")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# createSnippet
#
# POST /restv2/game/{apiKey}/manage/snippets
# operationId: createSnippetUsingPOST
export def "restv2-game-manage-snippets createSnippetUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list
  --name: string
  --script: string
  --scriptData: string
  --shortCode: string
  --template: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snippets")
  let body = {groups: $groups, name: $name, script: $script, scriptData: $scriptData, shortCode: $shortCode, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# deleteSnippet
#
# DELETE /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: deleteSnippetUsingDELETE
export def "restv2-game-manage-snippets delete" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snippets/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getSnippet
#
# GET /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: getSnippetUsingGET
export def "restv2-game-manage-snippets get" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snippets/($shortCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# updateSnippet
#
# PUT /restv2/game/{apiKey}/manage/snippets/{shortCode}
# operationId: updateSnippetUsingPUT
export def "restv2-game-manage-snippets updateSnippetUsingPUT" [
  apiKey: string
  shortCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --groups: list
  --name: string
  --script: string
  --scriptData: string
  --body-shortCode: string
  --template: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/manage/snippets/($shortCode)")
  let body = {groups: $groups, name: $name, script: $script, scriptData: $scriptData, shortCode: $body_shortCode, template: $template} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# restoreDeletedGame
#
# POST /restv2/game/{apiKey}/restore
# operationId: restoreDeletedGameUsingPOST
export def "restv2-game-restore restoreDeletedGameUsingPOST" [
  apiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($apiKey)/restore")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# setGameRegion
#
# POST /restv2/game/{gameApiKey}/region/{regionCode}
# operationId: setGameRegionUsingPOST
export def "restv2-game-region setGameRegionUsingPOST" [
  gameApiKey: string
  regionCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($gameApiKey)/region/($regionCode)")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# getGameRegionOptions
#
# GET /restv2/game/{gameApiKey}/regions
# operationId: getGameRegionOptionsUsingGET
export def "restv2-game-regions get" [
  gameApiKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/restv2/game/($gameApiKey)/regions")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# list
#
# GET /restv2/games
# operationId: listUsingGET
export def "restv2-games listUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# listDeleted
#
# GET /restv2/games/deleted
# operationId: listDeletedUsingGET
export def "restv2-games-deleted listDeletedUsingGET" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "accesstoken"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/restv2/games/deleted")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
