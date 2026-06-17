# Auto-generated client for Yodlee Core APIs v1.1.0
# Source: https://api.apis.guru/v2/specs/yodlee.com/1.1.0/openapi.json
# Auth: --token flag or $env.YODLEE_CORE_APIS_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o YODLEE_CORE_APIS_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def event-name-completer [] { ["AUTO_REFRESH_UPDATES" "DATA_UPDATES" "REFRESH"] }
def aggregation-source-completer [] { ["SYSTEM" "USER"] }
def source-completer [] { ["SYSTEM" "USER"] }
def action-completer [] { ["run"] }
def container-completer [] { ["bank" "creditCard" "insurance" "investment" "loan" "otherAssets" "otherLiabilities" "realEstate" "reward"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts get-all" } } | get name | first)
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
# GET /accounts
# operationId: getAllAccounts
export def "accounts get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds.
  --container: string # bank/creditCard/investment/insurance/loan/reward/realEstate/otherAssets/otherLiabilities
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefresh<br><b>Note:</b>fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
  --provider-account-id: string # Comma separated providerAccountIds.
  --request-id: string # The unique identifier that returns contextual data
  --status: string # ACTIVE,INACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add Manual Account
#
# POST /accounts
# operationId: createManualAccount
# --account shape: {accountName: string, accountNumber?: string, accountType: string, address?: record, amountDue?: record, balance?: record, dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, memo?: string, nickname?: string, valuationType?: "SYSTEM"|"MANUAL"}
export def "accounts create-manual" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName: string, accountNumber?: string, accountType: string, address?: record, amountDue?: record, balance?: record, dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, memo?: string, nickname?: string, valuationType?: "SYSTEM"|"MANUAL"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let body = {"account": $account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Evaluate Address
#
# POST /accounts/evaluateAddress
# operationId: evaluateAddress
# --address shape: {address1?: string, address2?: string, address3?: string, city?: string, country?: string, sourceType?: string, state?: string, street: string, type?: "HOME"|"BUSINESS"|"POBOX"|"RETAIL"|"OFFICE"|"SMALL_BUSINESS"|"COMMUNICATION"|"PERMANENT"|"STATEMENT_ADDRESS"|"PAYMENT"|"PAYOFF"|"UNKNOWN", zip?: string}
export def "accounts-evaluate-address evaluateAddress" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {address1?: string, address2?: string, address3?: string, city?: string, country?: string, sourceType?: string, state?: string, street: string, type?: "HOME"|"BUSINESS"|"POBOX"|"RETAIL"|"OFFICE"|"SMALL_BUSINESS"|"COMMUNICATION"|"PERMANENT"|"STATEMENT_ADDRESS"|"PAYMENT"|"PAYOFF"|"UNKNOWN", zip?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/evaluateAddress")
  let body = {"address": $address} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Historical Balances
#
# GET /accounts/historicalBalances
# operationId: getHistoricalBalances
export def "accounts-historical-balances get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include-cf: oneof<nothing, bool> # Consider carry forward logic for missing balances
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "includeCF" $include_cf "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts/historicalBalances" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Account
#
# DELETE /accounts/{accountId}
# operationId: deleteAccount
export def "accounts delete" [
  account_id: int
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
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Account Details
#
# GET /accounts/{accountId}
# operationId: getAccount
export def "accounts get" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefresh<br><b>Note:</b>fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account
#
# PUT /accounts/{accountId}
# operationId: updateAccount
# --account shape: {accountName?: string, accountNumber?: string, accountStatus?: "ACTIVE"|"INACTIVE"|"TO_BE_CLOSED"|"CLOSED"|"DELETED", address?: record, amountDue?: record, balance?: record, container?: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, isEbillEnrolled?: string, memo?: string, nickname?: string}
export def "accounts update" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName?: string, accountNumber?: string, accountStatus?: "ACTIVE"|"INACTIVE"|"TO_BE_CLOSED"|"CLOSED"|"DELETED", address?: record, amountDue?: record, balance?: record, container?: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, isEbillEnrolled?: string, memo?: string, nickname?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({account_id: $account_id} | format pattern "/accounts/{account_id}"))
  let body = {"account": $account} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get API Keys
#
# GET /auth/apiKey
# operationId: getApiKeys
export def "auth-api-key get" [
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
  let full_url = (build-url $base "/auth/apiKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate API Key
#
# POST /auth/apiKey
# operationId: generateApiKey
export def "auth-api-key generateApiKey" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-key: string # Public key uploaded by the customer while generating ApiKey.<br><br><b>Endpoints</b>:<ul><li>GET /auth/apiKey</li><li>POST /auth/apiKey</li></ul>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/apiKey")
  let body = {"publicKey": $public_key} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete API Key
#
# DELETE /auth/apiKey/{key}
# operationId: deleteApiKey
export def "auth-api-key delete" [
  key: string
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
  let full_url = (build-url $base ({key: $key} | format pattern "/auth/apiKey/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Token
#
# DELETE /auth/token
# operationId: deleteToken
export def "auth-token delete" [
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
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate Access Token
#
# POST /auth/token
# operationId: generateAccessToken
export def "auth-token generateAccessToken" [
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
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscribed Events
#
# GET /cobrand/config/notifications/events
# DEPRECATED
# operationId: getSubscribedEvents
@deprecated
export def "cobrand-config-notifications-events get-subscribed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cobrand/config/notifications/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Subscription
#
# DELETE /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: deleteSubscribedEvent
@deprecated
export def "cobrand-config-notifications-events delete-subscribed" [
  event_name: string
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
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe Event
#
# POST /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: createSubscriptionEvent
# --event shape: {callbackUrl?: string}
@deprecated
export def "cobrand-config-notifications-events create-subscription" [
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let body = {"event": $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Subscription
#
# PUT /cobrand/config/notifications/events/{eventName}
# DEPRECATED
# operationId: updateSubscribedEvent
# --event shape: {callbackUrl?: string}
@deprecated
export def "cobrand-config-notifications-events update-subscribed" [
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let body = {"event": $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cobrand Login
#
# POST /cobrand/login
# operationId: cobrandLogin
# --cobrand shape: {cobrandLogin: string, cobrandPassword: string, locale?: string}
export def "cobrand-login cobrandLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cobrand: record # shape: {cobrandLogin: string, cobrandPassword: string, locale?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cobrand/login")
  let body = {"cobrand": $cobrand} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cobrand Logout
#
# POST /cobrand/logout
# operationId: cobrandLogout
export def "cobrand-logout cobrandLogout" [
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
  let full_url = (build-url $base "/cobrand/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Public Key
#
# GET /cobrand/publicKey
# DEPRECATED
# operationId: getPublicKey
@deprecated
export def "cobrand-public-key get" [
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
  let full_url = (build-url $base "/cobrand/publicKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Subscribed Notification Events
#
# GET /configs/notifications/events
# operationId: getSubscribedNotificationEvents
export def "configs-notifications-events get-subscribed" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configs/notifications/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Notification Subscription
#
# DELETE /configs/notifications/events/{eventName}
# operationId: deleteSubscribedNotificationEvent
export def "configs-notifications-events delete-subscribed" [
  event_name: string
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
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/configs/notifications/events/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Subscribe For Notification Event
#
# POST /configs/notifications/events/{eventName}
# operationId: createSubscriptionNotificationEvent
# --event shape: {callbackUrl?: string}
export def "configs-notifications-events create-subscription" [
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/configs/notifications/events/{event_name}"))
  let body = {"event": $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Notification Subscription
#
# PUT /configs/notifications/events/{eventName}
# operationId: updateSubscribedNotificationEvent
# --event shape: {callbackUrl?: string}
export def "configs-notifications-events update-subscribed" [
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({event_name: $event_name} | format pattern "/configs/notifications/events/{event_name}"))
  let body = {"event": $event} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Public Key
#
# GET /configs/publicKey
# operationId: getPublicEncryptionKey
export def "configs-public-key get-public-encryption" [
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
  let full_url = (build-url $base "/configs/publicKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Events
#
# GET /dataExtracts/events
# operationId: getDataExtractsEvents
export def "data-extracts-events get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string # Event Name
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ)
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataExtracts/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get userData
#
# GET /dataExtracts/userData
# operationId: getDataExtractsUserData
export def "data-extracts-user-data get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ)
  --login-name: string # Login Name
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "loginName" $login_name "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataExtracts/userData" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Holding Summary
#
# GET /derived/holdingSummary
# operationId: getHoldingSummary
export def "derived-holding-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # Comma separated accountIds
  --classification-type: string # e.g. Country, Sector, etc.
  --include: string # details
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountIds" $account_ids "scalar") (serialize-qp "classificationType" $classification_type "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/holdingSummary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Networth Summary
#
# GET /derived/networth
# operationId: getNetworth
export def "derived-networth get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # comma separated accountIds
  --container: string # bank/creditCard/investment/insurance/loan/realEstate/otherAssets/otherLiabilities
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include: string # details
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountIds" $account_ids "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/networth" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transaction Summary
#
# GET /derived/transactionSummary
# operationId: getTransactionSummary
export def "derived-transaction-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # comma separated account Ids
  --category-id: string # comma separated categoryIds
  --category-type: string # INCOME, EXPENSE, TRANSFER, UNCATEGORIZE or DEFERRED_COMPENSATION
  --from-date: string # YYYY-MM-DD format
  --group-by: string # CATEGORY_TYPE, HIGH_LEVEL_CATEGORY or CATEGORY
  --include: string # details
  --include-user-category: oneof<nothing, bool> # TRUE/FALSE
  --interval: string # D-daily, W-weekly, M-mothly or Y-yearly
  --to-date: string # YYYY-MM-DD format
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "groupBy" $group_by "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "includeUserCategory" $include_user_category "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/transactionSummary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Documents
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
  --keyword: string # The string used to search a document by its name.
  --account-id: string # The unique identifier of an account. Retrieve documents for a given accountId.
  --doc-type: string # Accepts only one of the following valid document types: STMT, TAX, and EBILL.
  --from-date: string # The date from which documents have to be retrieved.
  --to-date: string # The date to which documents have to be retrieved.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Keyword" $keyword "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "docType" $doc_type "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Document
#
# DELETE /documents/{documentId}
# operationId: deleteDocument
export def "documents delete" [
  document_id: string
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
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Download a Document
#
# GET /documents/{documentId}
# operationId: downloadDocument
export def "documents download" [
  document_id: string
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
  let full_url = (build-url $base ({document_id: $document_id} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Holdings
#
# GET /holdings
# operationId: getHoldings
export def "holdings get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --asset-classification-classification-type: string # e.g. Country, Sector, etc.
  --classification-value: string # e.g. US
  --include: string # assetClassification
  --provider-account-id: string # providerAccountId
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "assetClassification.classificationType" $asset_classification_classification_type "scalar") (serialize-qp "classificationValue" $classification_value "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/holdings" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Asset Classification List
#
# GET /holdings/assetClassificationList
# operationId: getAssetClassificationList
export def "holdings-asset-classification-list get" [
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
  let full_url = (build-url $base "/holdings/assetClassificationList")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Holding Type List
#
# GET /holdings/holdingTypeList
# operationId: getHoldingTypeList
export def "holdings-holding-type-list get" [
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
  let full_url = (build-url $base "/holdings/holdingTypeList")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Security Details
#
# GET /holdings/securities
# operationId: getSecurities
export def "holdings-securities get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --holding-id: string # Comma separated holdingId
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "holdingId" $holding_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/holdings/securities" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Provider Accounts
#
# GET /providerAccounts
# operationId: getAllProviderAccounts
export def "provider-accounts get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include
  --provider-ids: string # Comma separated providerIds.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "providerIds" $provider_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Account
#
# PUT /providerAccounts
# operationId: editCredentialsOrRefreshProviderAccount
# --dataset item shape: {attribute?: list, name?: "BASIC_AGG_DATA"|"ADVANCE_AGG_DATA"|"ACCT_PROFILE"|"DOCUMENT"}
# --field item shape: {id?: string, image?: string, value?: string}
# --preferences shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
export def "provider-accounts editCredentialsOrRefreshProviderAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-ids: string # comma separated providerAccountIds
  --aggregation-source: string@aggregation-source-completer
  --consent-id: int # Consent Id generated for the request through POST Consent.<br><br><b>Endpoints</b>:<ul><li>POST Provider Account</li><li>PUT Provider Account</li></ul> (format: int64)
  --dataset: list # item shape: {attribute?: list, name?: "BASIC_AGG_DATA"|"ADVANCE_AGG_DATA"|"ACCT_PROFILE"|"DOCUMENT"}
  --dataset-name: list
  field: list # item shape: {id?: string, image?: string, value?: string}
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerAccountIds" $provider_account_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts" $qp)
  let body = {"aggregationSource": $aggregation_source, "consentId": $consent_id, "dataset": $dataset, "datasetName": $dataset_name, "field": $field, "preferences": $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get User Profile Details
#
# GET /providerAccounts/profile
# operationId: getProviderAccountProfiles
export def "provider-accounts-profile get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-id: string # Comma separated providerAccountIds.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerAccountId" $provider_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts/profile" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Provider Account
#
# DELETE /providerAccounts/{providerAccountId}
# operationId: deleteProviderAccount
export def "provider-accounts delete" [
  provider_account_id: int
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
  let full_url = (build-url $base ({provider_account_id: $provider_account_id} | format pattern "/providerAccounts/{provider_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Provider Account Details
#
# GET /providerAccounts/{providerAccountId}
# operationId: getProviderAccount
export def "provider-accounts get" [
  provider_account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include credentials,questions
  --request-id: string # The unique identifier for the request that returns contextual data
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({provider_account_id: $provider_account_id} | format pattern "/providerAccounts/{provider_account_id}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Preferences
#
# PUT /providerAccounts/{providerAccountId}/preferences
# operationId: updatePreferences
# --preferences shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
export def "provider-accounts-preferences update" [
  provider_account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_account_id: $provider_account_id} | format pattern "/providerAccounts/{provider_account_id}/preferences"))
  let body = {"preferences": $preferences} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Providers
#
# GET /providers
# operationId: getAllProviders
export def "providers get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # CHALLENGE_DEPOSIT_VERIFICATION - capability search is deprecated
  --dataset-filter: string # Expression to filter the providers by dataset(s) or dataset attribute(s). The default value will be the dataset or dataset attributes configured as default for the customer.
  --full-account-number-fields: string # Specify to filter the providers with values paymentAccountNumber,unmaskedAccountNumber.
  --institution-id: int # Institution Id for Single site selection (format: int64)
  --name: string # Name in minimum 1 character or routing number.
  --priority: string # Search priority
  --provider-id: string # Max 5 Comma seperated Provider Ids
  --skip: int # skip (Min 0) - This is not applicable along with 'name' parameter. (format: int32)
  --top: int # top (Max 500) - This is not applicable along with 'name' parameter. (format: int32)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "capability" $capability "scalar") (serialize-qp "dataset$filter" $dataset_filter "scalar") (serialize-qp "fullAccountNumberFields" $full_account_number_fields "scalar") (serialize-qp "institutionId" $institution_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "providerId" $provider_id "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Providers Count
#
# GET /providers/count
# operationId: getProvidersCount
export def "providers-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # CHALLENGE_DEPOSIT_VERIFICATION - capability search is deprecated
  --dataset-filter: string # Expression to filter the providers by dataset(s) or dataset attribute(s). The default value will be the dataset or dataset attributes configured as default for the customer.
  --full-account-number-fields: string # Specify to filter the providers with values paymentAccountNumber,unmaskedAccountNumber.
  --name: string # Name in minimum 1 character or routing number.
  --priority: string # Search priority
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "capability" $capability "scalar") (serialize-qp "dataset$filter" $dataset_filter "scalar") (serialize-qp "fullAccountNumberFields" $full_account_number_fields "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/count" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Provider Details
#
# GET /providers/{providerId}
# operationId: getProvider
export def "providers get" [
  provider_id: int
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
  let full_url = (build-url $base ({provider_id: $provider_id} | format pattern "/providers/{provider_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Statements
#
# GET /statements
# operationId: getStatements
export def "statements get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --container: string # creditCard/loan/insurance
  --from-date: string # from date for statement retrieval (YYYY-MM-DD)
  --is-latest: string # isLatest (true/false)
  --status: string # ACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "isLatest" $is_latest "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statements" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transactions
#
# GET /transactions
# operationId: getTransactions
export def "transactions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds
  --base-type: string # DEBIT/CREDIT
  --category-id: string # Comma separated categoryIds
  --category-type: string # Transaction Category Type(UNCATEGORIZE, INCOME, TRANSFER, EXPENSE or DEFERRED_COMPENSATION)
  --container: string # bank/creditCard/investment/insurance/loan
  --detail-category-id: string # Comma separated detailCategoryIds
  --from-date: string # Transaction from date(YYYY-MM-DD)
  --high-level-category-id: string # Comma separated highLevelCategoryIds
  --keyword: string # Transaction search text
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # Transaction end date (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
  --type: string # Transaction Type(SELL,SWEEP, etc.) for bank/creditCard/investment
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "baseType" $base_type "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "detailCategoryId" $detail_category_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "highLevelCategoryId" $high_level_category_id "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transaction Category List
#
# GET /transactions/categories
# operationId: getTransactionCategories
export def "transactions-categories get" [
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
  let full_url = (build-url $base "/transactions/categories")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Category
#
# POST /transactions/categories
# operationId: createTransactionCategory
export def "transactions-categories create-transaction-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-name: string
  parent_category_id: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories")
  let body = {"categoryName": $category_name, "parentCategoryId": $parent_category_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Category
#
# PUT /transactions/categories
# operationId: updateTransactionCategory
export def "transactions-categories update-transaction-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-name: string
  --high-level-category-name: string
  id: int # format: int64
  --body-source: string@source-completer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories")
  let body = {"categoryName": $category_name, "highLevelCategoryName": $high_level_category_name, "id": $id, "source": $body_source} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/rules
# DEPRECATED
# operationId: getTransactionCategorizationRulesDeprecated
@deprecated
export def "transactions-categories-rules get-transaction-categorization-rules-deprecated" [
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
  let full_url = (build-url $base "/transactions/categories/rules")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or Run Transaction Categorization Rule
#
# POST /transactions/categories/rules
# operationId: createOrRunTransactionCategorizationRules
export def "transactions-categories-rules create-or-run-transaction-categorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string # To run rules, pass action=run. Only value run is supported
  --rule-param: string # rules(JSON format) to categorize the transactions
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar") (serialize-qp "ruleParam" $rule_param "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions/categories/rules" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Transaction Categorization Rule
#
# DELETE /transactions/categories/rules/{ruleId}
# operationId: deleteTransactionCategorizationRule
export def "transactions-categories-rules delete-transaction-categorization" [
  rule_id: int
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
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/transactions/categories/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run Transaction Categorization Rule
#
# POST /transactions/categories/rules/{ruleId}
# operationId: runTransactionCategorizationRule
export def "transactions-categories-rules runTransactionCategorizationRule" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # default: run
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/transactions/categories/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Transaction Categorization Rule
#
# PUT /transactions/categories/rules/{ruleId}
# operationId: updateTransactionCategorizationRule
# --rule shape: {categoryId: int, priority?: int, ruleClause: list, source?: "SYSTEM"|"USER"}
export def "transactions-categories-rules update-transaction-categorization" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  rule: record # shape: {categoryId: int, priority?: int, ruleClause: list, source?: "SYSTEM"|"USER"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({rule_id: $rule_id} | format pattern "/transactions/categories/rules/{rule_id}"))
  let body = {"rule": $rule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/txnRules
# operationId: getTransactionCategorizationRules
export def "transactions-categories-txn-rules get-transaction-categorization" [
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
  let full_url = (build-url $base "/transactions/categories/txnRules")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Category
#
# DELETE /transactions/categories/{categoryId}
# operationId: deleteTransactionCategory
export def "transactions-categories delete-transaction-category" [
  category_id: int
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
  let full_url = (build-url $base ({category_id: $category_id} | format pattern "/transactions/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Transactions Count
#
# GET /transactions/count
# operationId: getTransactionsCount
export def "transactions-count get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds	
  --base-type: string # DEBIT/CREDIT
  --category-id: string # Comma separated categoryIds
  --category-type: string # Transaction Category Type(UNCATEGORIZE, INCOME, TRANSFER, EXPENSE or DEFERRED_COMPENSATION)
  --container: string # bank/creditCard/investment/insurance/loan
  --detail-category-id: string # Comma separated detailCategoryIds
  --from-date: string # Transaction from date(YYYY-MM-DD)
  --high-level-category-id: string # Comma separated highLevelCategoryIds
  --keyword: string # Transaction search text	
  --to-date: string # Transaction end date (YYYY-MM-DD)
  --type: string # Transaction Type(SELL,SWEEP, etc.)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "baseType" $base_type "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "detailCategoryId" $detail_category_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "highLevelCategoryId" $high_level_category_id "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions/count" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Transaction
#
# PUT /transactions/{transactionId}
# operationId: updateTransaction
# --transaction shape: {categoryId: int, categorySource: "SYSTEM"|"USER", container: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", description?: record, memo?: string}
export def "transactions update" [
  transaction_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: record # shape: {categoryId: int, categorySource: "SYSTEM"|"USER", container: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", description?: record, memo?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_id: $transaction_id} | format pattern "/transactions/{transaction_id}"))
  let body = {"transaction": $transaction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get User Details
#
# GET /user
# operationId: getUser
export def "user get" [
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
  let full_url = (build-url $base "/user")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update User Details
#
# PUT /user
# operationId: updateUser
# --user shape: {address?: record, email?: string, name?: record, preferences?: record, segmentName?: string}
export def "user update" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, name?: record, preferences?: record, segmentName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let body = {"user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Access Tokens
#
# GET /user/accessTokens
# operationId: getAccessTokens
export def "user-access-tokens get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-ids: string # appIds
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appIds" $app_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/accessTokens" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# User Logout
#
# POST /user/logout
# operationId: userLogout
export def "user-logout userLogout" [
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
  let full_url = (build-url $base "/user/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Register User
#
# POST /user/register
# operationId: registerUser
# --user shape: {address?: record, email?: string, loginName: string, name?: record, preferences?: record, segmentName?: string}
export def "user-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, loginName: string, name?: record, preferences?: record, segmentName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/register")
  let body = {"user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Saml Login
#
# POST /user/samlLogin
# operationId: samlLogin
export def "user-saml-login samlLogin" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --issuer: string # issuer
  --saml-response: string # samlResponse
  --qp-source: string # source
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "issuer" $issuer "scalar") (serialize-qp "samlResponse" $saml_response "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/samlLogin" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete User
#
# DELETE /user/unregister
# operationId: unregister
export def "user-unregister unregister" [
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
  let full_url = (build-url $base "/user/unregister")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Verification Status
#
# GET /verification
# operationId: getVerificationStatus
export def "verification get-verification-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --provider-account-id: string # Comma separated providerAccountId
  --verification-type: string # verificationType
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar") (serialize-qp "verificationType" $verification_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verification" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Initiaite Matching Service and Challenge Deposit
#
# POST /verification
# operationId: initiateMatchingOrChallengeDepositeVerification
# --verification shape: {account?: record, accountId?: int, providerAccountId?: int, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
export def "verification initiateMatchingOrChallengeDepositeVerification" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verification")
  let body = {"verification": $verification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify Challenge Deposit
#
# PUT /verification
# operationId: verifyChallengeDeposit
# --verification shape: {account?: record, accountId?: int, providerAccountId?: int, transaction: list, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
export def "verification verify-challenge-deposit" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, transaction: list, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verification")
  let body = {"verification": $verification} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Verify Accounts Using Transactions
#
# POST /verifyAccount/{providerAccountId}
# operationId: initiateAccountVerification
# --transactionCriteria item shape: {amount: float, baseType?: "CREDIT"|"DEBIT", date: string, dateVariance?: string, keyword?: string}
export def "verify-account initiateAccountVerification" [
  provider_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # format: int64
  --container: string@container-completer
  transaction_criteria: list # item shape: {amount: float, baseType?: "CREDIT"|"DEBIT", date: string, dateVariance?: string, keyword?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({provider_account_id: $provider_account_id} | format pattern "/verifyAccount/{provider_account_id}"))
  let body = {"accountId": $account_id, "container": $container, "transactionCriteria": $transaction_criteria} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
