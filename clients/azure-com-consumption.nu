# Auto-generated client for ConsumptionManagementClient v2019-06-01
# Source: https://api.apis.guru/v2/specs/azure.com/consumption/2019-06-01/swagger.json
# Auth: --token flag or $env.CONSUMPTIONMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONSUMPTIONMANAGEMENTCLIENT_TOKEN | default "" }
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

# Percent-encode a path-segment value per RFC 3986.
# Unreserved chars ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def grain-completer [] { ["daily" "monthly"] }
def metric-completer [] { ["actualcost" "amortizedcost" "usage"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-billing-billing-accounts-providers-microsoft-billing-billing-periods-providers-microsoft-consumption-balances get-for" } } | get name | first)
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

# Gets the balances for a scope by billing period and billingAccountId. Balances are available via this API only for May 1, 2014 or later.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/Microsoft.Billing/billingPeriods/{billingPeriodName}/providers/Microsoft.Consumption/balances
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Balances_GetForBillingPeriodByBillingAccount
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-billing-billing-periods-providers-microsoft-consumption-balances get-for" [
  billing_account_id: string
  billing_period_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<adjustmentDetails: list<record>, adjustments: float, azureMarketplaceServiceCharges: float, beginningBalance: float, billingFrequency: string, chargesBilledSeparately: float, currency: string, endingBalance: float, newPurchases: float, newPurchasesDetails: list<record>, priceHidden: bool, serviceOverage: float, totalOverage: float, totalUsage: float, utilized: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id), billing_period_name: (encode-path-segment $billing_period_name)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/Microsoft.Billing/billingPeriods/{billing_period_name}/providers/Microsoft.Consumption/balances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the balances for a scope by billingAccountId. Balances are available via this API only for May 1, 2014 or later.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/Microsoft.Consumption/balances
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Balances_GetByBillingAccount
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-consumption-balances get" [
  billing_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<adjustmentDetails: list<record>, adjustments: float, azureMarketplaceServiceCharges: float, beginningBalance: float, billingFrequency: string, chargesBilledSeparately: float, currency: string, endingBalance: float, newPurchases: float, newPurchasesDetails: list<record>, priceHidden: bool, serviceOverage: float, totalOverage: float, totalUsage: float, utilized: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/Microsoft.Consumption/balances") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations details for provided date range.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/Microsoft.Consumption/reservationDetails
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsDetails_ListByBillingAccountId
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-consumption-reservation-details list" [
  billing_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter reservation details by date range. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/Microsoft.Consumption/reservationDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations summaries for daily or monthly grain.
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/Microsoft.Consumption/reservationSummaries
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsSummaries_ListByBillingAccountId
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-consumption-reservation-summaries list" [
  billing_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grain: string@grain-completer # Can be daily or monthly
  --filter: string # Required only for daily grain. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grain" $grain "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/Microsoft.Consumption/reservationSummaries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of transactions for reserved instances on billing account scope
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/Microsoft.Consumption/reservationTransactions
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationTransactions_ListByBillingAccountId
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-consumption-reservation-transactions list" [
  billing_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter reservation transactions by date range. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/Microsoft.Consumption/reservationTransactions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of recommendations for purchasing reserved instances on billing account scope
#
# GET /providers/Microsoft.Billing/billingAccounts/{billingAccountId}/providers/microsoft.consumption/ReservationRecommendations
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationRecommendations_ListByBillingAccountId
export def "providers-microsoft-billing-billing-accounts-providers-microsoft-consumption-reservation-recommendations list" [
  billing_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # May be used to filter reservationRecommendations by properties/scope and properties/lookBackPeriod.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({billing_account_id: (encode-path-segment $billing_account_id)} | format pattern "/providers/Microsoft.Billing/billingAccounts/{billing_account_id}/providers/microsoft.consumption/ReservationRecommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations details for provided date range.
#
# GET /providers/Microsoft.Capacity/reservationorders/{reservationOrderId}/providers/Microsoft.Consumption/reservationDetails
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsDetails_ListByReservationOrder
export def "providers-microsoft-capacity-reservationorders-providers-microsoft-consumption-reservation-details list-by-order" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter reservation details by date range. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationorders/{reservation_order_id}/providers/Microsoft.Consumption/reservationDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations summaries for daily or monthly grain.
#
# GET /providers/Microsoft.Capacity/reservationorders/{reservationOrderId}/providers/Microsoft.Consumption/reservationSummaries
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsSummaries_ListByReservationOrder
export def "providers-microsoft-capacity-reservationorders-providers-microsoft-consumption-reservation-summaries list-by-order" [
  reservation_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grain: string@grain-completer # Can be daily or monthly
  --filter: string # Required only for daily grain. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grain" $grain "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id)} | format pattern "/providers/Microsoft.Capacity/reservationorders/{reservation_order_id}/providers/Microsoft.Consumption/reservationSummaries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations details for provided date range.
#
# GET /providers/Microsoft.Capacity/reservationorders/{reservationOrderId}/reservations/{reservationId}/providers/Microsoft.Consumption/reservationDetails
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsDetails_ListByReservationOrderAndReservation
export def "providers-microsoft-capacity-reservationorders-reservations-providers-microsoft-consumption-reservation-details list-by-order-and" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Filter reservation details by date range. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationorders/{reservation_order_id}/reservations/{reservation_id}/providers/Microsoft.Consumption/reservationDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the reservations summaries for daily or monthly grain.
#
# GET /providers/Microsoft.Capacity/reservationorders/{reservationOrderId}/reservations/{reservationId}/providers/Microsoft.Consumption/reservationSummaries
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationsSummaries_ListByReservationOrderAndReservation
export def "providers-microsoft-capacity-reservationorders-reservations-providers-microsoft-consumption-reservation-summaries list-by-order-and" [
  reservation_order_id: string
  reservation_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --grain: string@grain-completer # Can be daily or monthly
  --filter: string # Required only for daily grain. The properties/UsageDate for start date and end date. The filter supports 'le' and 'ge'
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "grain" $grain "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({reservation_order_id: (encode-path-segment $reservation_order_id), reservation_id: (encode-path-segment $reservation_id)} | format pattern "/providers/Microsoft.Capacity/reservationorders/{reservation_order_id}/reservations/{reservation_id}/providers/Microsoft.Consumption/reservationSummaries") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all of the available consumption REST API operations.
#
# GET /providers/Microsoft.Consumption/operations
# operationId: Operations_List
export def "providers-microsoft-consumption-operations list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Consumption/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides the aggregate cost of a management group and all child management groups by specified billing period
#
# GET /providers/Microsoft.Management/managementGroups/{managementGroupId}/providers/Microsoft.Billing/billingPeriods/{billingPeriodName}/Microsoft.Consumption/aggregatedcost
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: AggregatedCost_GetForBillingPeriodByManagementGroup
export def "providers-microsoft-management-management-groups-providers-microsoft-billing-billing-periods-microsoft-consumption-aggregatedcost get-aggregated-cost-for" [
  management_group_id: string
  billing_period_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<azureCharges: float, billingPeriodId: string, chargesBilledSeparately: float, children: list<any>, currency: string, excludedSubscriptions: list<string>, includedSubscriptions: list<string>, marketplaceCharges: float, usageEnd: string, usageStart: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({management_group_id: (encode-path-segment $management_group_id), billing_period_name: (encode-path-segment $billing_period_name)} | format pattern "/providers/Microsoft.Management/managementGroups/{management_group_id}/providers/Microsoft.Billing/billingPeriods/{billing_period_name}/Microsoft.Consumption/aggregatedcost") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provides the aggregate cost of a management group and all child management groups by current billing period.
#
# GET /providers/Microsoft.Management/managementGroups/{managementGroupId}/providers/Microsoft.Consumption/aggregatedcost
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: AggregatedCost_GetByManagementGroup
export def "providers-microsoft-management-management-groups-providers-microsoft-consumption-aggregatedcost get-aggregated-cost" [
  management_group_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
  --filter: string # May be used to filter aggregated cost by properties/usageStart (Utc time), properties/usageEnd (Utc time). The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<properties: record<azureCharges: float, billingPeriodId: string, chargesBilledSeparately: float, children: list<any>, currency: string, excludedSubscriptions: list<string>, includedSubscriptions: list<string>, marketplaceCharges: float, usageEnd: string, usageStart: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({management_group_id: (encode-path-segment $management_group_id)} | format pattern "/providers/Microsoft.Management/managementGroups/{management_group_id}/providers/Microsoft.Consumption/aggregatedcost") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the price sheet for a scope by subscriptionId and billing period. Price sheet is available via this API only for May 1, 2014 or later.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Billing/billingPeriods/{billingPeriodName}/providers/Microsoft.Consumption/pricesheets/default
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: PriceSheet_GetByBillingPeriod
export def "subscriptions-providers-microsoft-billing-billing-periods-providers-microsoft-consumption-pricesheets-default get-price-sheet" [
  subscription_id: string
  billing_period_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # May be used to expand the properties/meterDetails within a price sheet. By default, these fields are not included when returning price sheet.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the top N results.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<nextLink: string, pricesheets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), billing_period_name: (encode-path-segment $billing_period_name)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Billing/billingPeriods/{billing_period_name}/providers/Microsoft.Consumption/pricesheets/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the forecast charges by subscriptionId.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Consumption/forecasts
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Forecasts_List
export def "subscriptions-providers-microsoft-consumption-forecasts list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # May be used to filter forecasts by properties/usageDate (Utc time), properties/chargeType or properties/grain. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Consumption/forecasts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the price sheet for a scope by subscriptionId. Price sheet is available via this API only for May 1, 2014 or later.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Consumption/pricesheets/default
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: PriceSheet_Get
export def "subscriptions-providers-microsoft-consumption-pricesheets-default get-price-sheet" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # May be used to expand the properties/meterDetails within a price sheet. By default, these fields are not included when returning price sheet.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the top N results.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<nextLink: string, pricesheets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Consumption/pricesheets/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List of recommendations for purchasing reserved instances.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Consumption/reservationRecommendations
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: ReservationRecommendations_List
export def "subscriptions-providers-microsoft-consumption-reservation-recommendations list" [
  subscription_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # May be used to filter reservationRecommendations by properties/scope and properties/lookBackPeriod.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id)} | format pattern "/subscriptions/{subscription_id}/providers/Microsoft.Consumption/reservationRecommendations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all budgets for the defined scope.
#
# GET /{scope}/providers/Microsoft.Consumption/budgets
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Budgets_List
export def "providers-microsoft-consumption-budgets list" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.Consumption/budgets") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to delete a budget.
#
# DELETE /{scope}/providers/Microsoft.Consumption/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Budgets_Delete
export def "providers-microsoft-consumption-budgets delete" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<error: record<code: string, message: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope), budget_name: (encode-path-segment $budget_name)} | format pattern "/{scope}/providers/Microsoft.Consumption/budgets/{budget_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the budget for the scope by budget name.
#
# GET /{scope}/providers/Microsoft.Consumption/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Budgets_Get
export def "providers-microsoft-consumption-budgets get" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<amount: float, category: string, currentSpend: record<amount: float, unit: string>, filters: record<meters: list, resourceGroups: list, resources: list, tags: record>, notifications: record, timeGrain: string, timePeriod: record<endDate: string, startDate: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope), budget_name: (encode-path-segment $budget_name)} | format pattern "/{scope}/providers/Microsoft.Consumption/budgets/{budget_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The operation to create or update a budget. Update operation requires latest eTag to be set in the request mandatorily. You may obtain the latest eTag by performing a get operation. Create operation does not require eTag.
#
# PUT /{scope}/providers/Microsoft.Consumption/budgets/{budgetName}
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Budgets_CreateOrUpdate
# --properties shape: {amount: float, category: "Cost"|"Usage", currentSpend?: any, filters?: any, notifications?: record, timeGrain: "Monthly"|"Quarterly"|"Annually"|"BillingMonth"|"BillingQuarter"|"BillingAnnual", timePeriod: any}
export def "providers-microsoft-consumption-budgets create-or-update" [
  scope: string
  budget_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
  --properties: any # The properties of the budget. — shape: {amount: float, category: "Cost"|"Usage", currentSpend?: any, filters?: any, notifications?: record, timeGrain: "Monthly"|"Quarterly"|"Annually"|"BillingMonth"|"BillingQuarter"|"BillingAnnual", timePeriod: any}
  --e-tag: string # eTag of the resource. To handle concurrent update scenario, this field will be used to determine whether the user is updating the latest version or not.
]: any -> record<properties: record<amount: float, category: string, currentSpend: record<amount: float, unit: string>, filters: record<meters: list, resourceGroups: list, resources: list, tags: record>, notifications: record, timeGrain: string, timePeriod: record<endDate: string, startDate: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope), budget_name: (encode-path-segment $budget_name)} | format pattern "/{scope}/providers/Microsoft.Consumption/budgets/{budget_name}") $qp)
  let req_body = {"properties": $properties, "eTag": $e_tag} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lists the charges based for the defined scope.
#
# GET /{scope}/providers/Microsoft.Consumption/charges
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Charges_ListByScope
export def "providers-microsoft-consumption-charges list" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
  --filter: string # May be used to filter charges by properties/usageEnd (Utc time), properties/usageStart (Utc time). The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:).
]: nothing -> record<properties: record<azureCharges: float, billingPeriodId: string, chargesBilledSeparately: float, currency: string, marketplaceCharges: float, usageEnd: string, usageStart: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.Consumption/charges") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the marketplaces for a scope at the defined scope. Marketplaces are available via this API only for May 1, 2014 or later.
#
# GET /{scope}/providers/Microsoft.Consumption/marketplaces
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Marketplaces_List
export def "providers-microsoft-consumption-marketplaces list" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # May be used to filter marketplaces by properties/usageEnd (Utc time), properties/usageStart (Utc time), properties/resourceGroup, properties/instanceName or properties/instanceId. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'.
  --top: int # May be used to limit the number of results to the most recent N marketplaces.
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$filter" $filter "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.Consumption/marketplaces") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all available tag keys for the defined scope
#
# GET /{scope}/providers/Microsoft.Consumption/tags
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: Tags_Get
export def "providers-microsoft-consumption-tags get" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
]: nothing -> record<properties: record<tags: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.Consumption/tags") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists the usage details for the defined scope. Usage details are available via this API only for May 1, 2014 or later.
#
# GET /{scope}/providers/Microsoft.Consumption/usageDetails
# Docs: https://docs.microsoft.com/en-us/rest/api/consumption/
# operationId: UsageDetails_List
export def "providers-microsoft-consumption-usage-details list" [
  scope: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --expand: string # May be used to expand the properties/additionalInfo or properties/meterDetails within a list of usage details. By default, these fields are not included when listing usage details.
  --filter: string # May be used to filter usageDetails by properties/resourceGroup, properties/resourceName, properties/resourceId, properties/chargeType, properties/reservationId, properties/publisherType or tags. The filter supports 'eq', 'lt', 'gt', 'le', 'ge', and 'and'. It does not currently support 'ne', 'or', or 'not'. Tag filter is a key value pair string where key and value is separated by a colon (:). PublisherType Filter accepts two values azure and marketplace and it is currently supported for Web Direct Offer Type
  --skiptoken: string # Skiptoken is only used if a previous operation returned a partial result. If a previous response contains a nextLink element, the value of the nextLink element will include a skiptoken parameter that specifies a starting point to use for subsequent calls.
  --top: int # May be used to limit the number of results to the most recent N usageDetails.
  --api-version: string # Version of the API to be used with the client request. The current version is 2019-06-01.
  --metric: string@metric-completer # Allows to select different type of cost/usage records.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$expand" $expand "scalar") (serialize-qp "$filter" $filter "scalar") (serialize-qp "$skiptoken" $skiptoken "scalar") (serialize-qp "$top" $top "scalar") (serialize-qp "api-version" $api_version "scalar") (serialize-qp "metric" $metric "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({scope: (encode-path-segment $scope)} | format pattern "/{scope}/providers/Microsoft.Consumption/usageDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
