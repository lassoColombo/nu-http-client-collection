# Auto-generated client for BeezUP Merchant API  v2.0
# Source: https://api.apis.guru/v2/specs/beezup.com/2.0/openapi.json
# Auth: --token flag or $env.BEEZUP_MERCHANT_API_TOKEN

const BASE_URL = "https://api.beezup.com"
const DEFAULT_AUTH = "ocp-apim-subscription-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BEEZUP_MERCHANT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "ocp-apim-subscription-key" => { {headers: {Ocp-Apim-Subscription-Key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.beezup.com"] }
def auth-scheme-completer [] { ["ocp-apim-subscription-key"] }

# Completers for enum parameters
def date-search-type-completer [] { ["MarketPlaceModification" "Modification" "Purchase"] }
def product-state-completer [] { ["All" "Disabled" "Enabled"] }
def report-type-completer [] { ["ByCategory" "ByChannel" "ByDay" "ByProduct"] }
def optimisation-action-name-completer [] { ["disable" "reenable"] }
def format-completer [] { ["csv" "xlsx"] }
def cost-type-completer [] { ["CPA_ByCategory" "CPA_Global" "CPC_ByCategory" "CPC_Global" "Fixed_Global"] }
def profile-picture-selected-completer [] { ["gravatar" "initials" "uploaded"] }
def feed-type-completer [] { ["Images" "Inventory" "Offers" "Pricing" "Products" "Relationships" "Unpublish"] }
def publication-strategy-kind-completer [] { ["Delta" "Full"] }
def format-completer-1 [] { ["csv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders-batches-change-orders list" } } | get name | first)
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

# Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders
# operationId: ChangeOrderListV3
# --changeOrders item shape: {changeOrderRequest?: record, order: any}
export def "orders-batches-change-orders list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: any}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/changeOrders" $qp)
  let req_body = {"changeOrders": $change_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders/{changeOrderType}
# operationId: ChangeOrderListV2
# --changeOrders item shape: {changeOrderRequest?: record, order: record}
export def "orders-batches-change-orders list-by-changeOrderType" [
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: record}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({change_order_type: (encode-path-segment $change_order_type)} | format pattern "/orders/v3/batches/changeOrders/{change_order_type}") $qp)
  let req_body = {"changeOrders": $change_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /orders/v3/batches/clearMerchantOrderInfos
# operationId: ClearMerchantOrderInfoListV3
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
export def "orders-batches-clear-merchant-order-infos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 5678, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 9876, beezUPOrderId: 0, marketplaceTechnicalCode: Ebay}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/clearMerchantOrderInfos" $qp)
  let req_body = {"orders": $orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Send a batch of operations to set an Order's merchant information (max 100 items per call)
#
# POST /orders/v3/batches/setMerchantOrderInfos
# operationId: SetMerchantOrderInfoListV3
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
export def "orders-batches-set-merchant-order-infos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/setMerchantOrderInfos" $qp)
  let req_body = {"order_MerchantECommerceSoftwareName": $order_merchant_e_commerce_software_name, "order_MerchantECommerceSoftwareVersion": $order_merchant_e_commerce_software_version, "orders": $orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Send harvest request to all your marketplaces
#
# POST /orders/v3/harvest
# operationId: HarvestAllV3
export def "orders-harvest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: StoreId, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/harvest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /orders/v3/list/full
# operationId: GetOrderListFullV3
export def "orders-list-full get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<links: record, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/v3/list/full")
  let req_body = {"accountIds": $account_ids, "beezUPOrderStatuses": $beez_up_order_statuses, "beginPeriodUtcDate": $begin_period_utc_date, "dateSearchType": $date_search_type, "endPeriodUtcDate": $end_period_utc_date, "invoiceAvailabilityType": $invoice_availability_type, "marketplaceBusinessCodes": $marketplace_business_codes, "marketplaceOrderIds": $marketplace_order_ids, "marketplaceTechnicalCodes": $marketplace_technical_codes, "orderMerchantInfoSynchronizationStatus": $order_merchant_info_synchronization_status, "order_Buyer_Name": $order_buyer_name, "order_MerchantOrderIds": $order_merchant_order_ids, "storeIds": $store_ids, "pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get a paginated list of all Orders without details
#
# POST /orders/v3/list/light
# operationId: GetOrderListLightV3
export def "orders-list-light get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/v3/list/light")
  let req_body = {"accountIds": $account_ids, "beezUPOrderStatuses": $beez_up_order_statuses, "beginPeriodUtcDate": $begin_period_utc_date, "dateSearchType": $date_search_type, "endPeriodUtcDate": $end_period_utc_date, "invoiceAvailabilityType": $invoice_availability_type, "marketplaceBusinessCodes": $marketplace_business_codes, "marketplaceOrderIds": $marketplace_order_ids, "marketplaceTechnicalCodes": $marketplace_technical_codes, "orderMerchantInfoSynchronizationStatus": $order_merchant_info_synchronization_status, "order_Buyer_Name": $order_buyer_name, "order_MerchantOrderIds": $order_merchant_order_ids, "storeIds": $store_ids, "pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the list of MarketplaceBusinessCode ready for Order Management
#
# GET /orders/v3/lov/orderManagementReadyMarketplaceBusinessCode
# operationId: GetOrderManagementReadyMarketplaceBusinessCode
export def "orders-lov-order-management-ready-marketplace-business-code get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-ids: list<string> # StoredIds to filter
  --accept-language: list<string> # Indicates that the client accepts the following languages.
]: nothing -> table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeIds" $store_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/lov/orderManagementReadyMarketplaceBusinessCode" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /orders/v3/status
# operationId: GetMarketplaceAccountsSynchronizationV3
export def "orders-status get-marketplace-accounts-synchronization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-ids: list<string> # StoredIds to filter
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeIds" $store_ids "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send harvest request for an Account
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/harvest
# operationId: HarvestAccount
export def "orders-harvest create-account" [
  marketplace_technical_code: string
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplace-order-id: string
  --beez-up-order-id: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplaceOrderId" $marketplace_order_id "scalar") (serialize-qp "beezUPOrderId" $beez_up_order_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/harvest") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get full Order and Order Item(s) properties
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# operationId: GetOrderV3
export def "orders get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# operationId: HeadOrderV3
export def "orders head-head" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# operationId: ClearMerchantOrderInfoV3
export def "orders-clear-merchant-order-info get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/clearMerchantOrderInfo") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send harvest request for a single Order
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest
# operationId: HarvestOrderV3
export def "orders-harvest create" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/harvest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Order's harvest and change history
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history
# operationId: GetOrderHistoryV3
export def "orders-history get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/history"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the order change reporting
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history/{orderChangeExecutionUUID}
# operationId: GetOrderChangeReportingV3
export def "orders-history get-change-reporting" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  order_change_execution_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id), order_change_execution_uuid: (encode-path-segment $order_change_execution_uuid)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/history/{order_change_execution_uuid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# operationId: SetMerchantOrderInfoV3
export def "orders-set-merchant-order-info update" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_merchant_order_id: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/setMerchantOrderInfo") $qp)
  let req_body = {"order_MerchantECommerceSoftwareName": $order_merchant_e_commerce_software_name, "order_MerchantECommerceSoftwareVersion": $order_merchant_e_commerce_software_version, "order_MerchantOrderId": $order_merchant_order_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change your marketplace Order Information (accept, ship, etc.)
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# operationId: ChangeOrderV3
export def "orders create-change" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id), change_order_type: (encode-path-segment $change_order_type)} | format pattern "/orders/v3/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/{change_order_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get public channel index
#
# GET /v2/public/channels/
# operationId: GetChannelsIndex
export def "public-channels get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<channels: record, links: record<channelCountryLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelTypeLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, sectorLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/channels/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The channel list for one country
#
# GET /v2/public/channels/{countryIsoCode}
# operationId: GetChannels
export def "public-channels get" [
  country_iso_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Allows the client to indicate whether it accepts a compressed encoding to reduce traffic size.
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<channels: table<homeUrl: string, logoUrl: string, name: string, sectors: list, types: list>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({country_iso_code: (encode-path-segment $country_iso_code)} | format pattern "/v2/public/channels/{country_iso_code}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all list names
#
# GET /v2/public/lov/
# operationId: GetPublicLovIndex
export def "public-lov get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/lov/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of values related to this list name
#
# GET /v2/public/lov/{listName}
# operationId: GetPublicListOfValues
export def "public-lov get-list-of-values" [
  list_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: list<string> # Indicates that the client accepts the following languages.
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_name: (encode-path-segment $list_name)} | format pattern "/v2/public/lov/{list_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login
#
# POST /v2/public/security/login
# operationId: Login
export def "public-security-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  login: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
  password: string # Your password (format: password, e.g. I@mW0nder$Full)
]: any -> record<credentials: table<primaryToken: string, productName: string, secondaryToken: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/security/login")
  let req_body = {"login": $login, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Lost password
#
# POST /v2/public/security/lostpassword
# operationId: LostPassword
export def "public-security-lostpassword create-lost-password" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/security/lostpassword")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# User Registration
#
# POST /v2/public/security/register
# operationId: Register
export def "public-security-register create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commercial-owner-user-id: string # The user id of your commercial in BeezUP. (format: uuid, e.g. 47ea14ab-195d-4f9a-a24e-32c329ee40f6)
  --culture-name: string # Can be null. Default: en-GB. The culture name you want to use. FYI. \ The email activation will use this culture. (e.g. en-GB)
  email: string # Your email. We refuse disposable email. (e.g. myemail@mycompany.com)
  password: string # The password you want to use for your new account. \ The password length must be greater or equals to 6 and lower or equals to 128. \ The password must contains at least one number and one special character (e.g. I@mW0nder$Full)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/security/register")
  let req_body = {"commercialOwnerUserId": $commercial_owner_user_id, "cultureName": $culture_name, "email": $email, "password": $password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the Analytics API operation index
#
# GET /v2/user/analytics/
# operationId: AnalyticsIndex
export def "user-analytics get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<analyticsNumericalProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsProductColumnFilterOperatorNameLov: record<href: string, method: string>, analyticsStringProductColumnFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFilterOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaOperatorNameLov: record<href: string, method: string>, performanceIndicatorFormulaParameterTypeLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByCategoryLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByChannelLov: record<href: string, method: string>, performanceIndicatorTypeForReportsByProductLov: record<href: string, method: string>, performanceIndicatorTypeLov: record<href: string, method: string>, storeOptimisationRuleExecutionStatusLov: record<href: string, method: string>>, stores: table<links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/analytics/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the report by day for a StoreId
#
# POST /v2/user/analytics/reports/byday
# operationId: GetStoreReportByDayPerStore
# --advancedFilters shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
export def "user-analytics-reports-byday get-store-by-day-per-store" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalog-category-id: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channel-ids: list<string> # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  end_period_utc_date: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --product-id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/analytics/reports/byday")
  let req_body = {"advancedFilters": $advanced_filters, "beginPeriodUtcDate": $begin_period_utc_date, "catalogCategoryId": $catalog_category_id, "channelIds": $channel_ids, "endPeriodUtcDate": $end_period_utc_date, "productId": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the global synchronization status of clicks and orders
#
# GET /v2/user/analytics/tracking/status
# operationId: GetTrackingStatus
export def "user-analytics-tracking-status get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/analytics/tracking/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Analytics API operation index for one store
#
# GET /v2/user/analytics/{storeId}
# operationId: AnalyticsStoreIndex
export def "user-analytics get-store-index" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<optimise: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseAll: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, optimiseByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByCategory: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByChannel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByDay: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportByProduct: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, rules: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedClicks: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedExternalOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackedOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, trackingStatus: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimise all products
#
# POST /v2/user/analytics/{storeId}/optimisations/all/{actionName}
# operationId: OptimiseAll
# --analyticsProductColumnFilters shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
export def "user-analytics-optimisations-all list-optimise" [
  store_id: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --analytics-product-column-filters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --product-columns-to-display: list<string> # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  --product-state: string@product-state-completer # You can filter on the product state. (default: All, e.g. All)
  report_type: string@report-type-completer # The report type (e.g. ByProduct)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), action_name: (encode-path-segment $action_name)} | format pattern "/v2/user/analytics/{store_id}/optimisations/all/{action_name}"))
  let req_body = {"analyticsProductColumnFilters": $analytics_product_column_filters, "productColumnsToDisplay": $product_columns_to_display, "productState": $product_state, "reportType": $report_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Optimise products by category
#
# POST /v2/user/analytics/{storeId}/optimisations/bycategory/{catalogCategoryId}/{actionName}
# operationId: OptimiseByCategory
export def "user-analytics-optimisations-bycategory create-optimise-by-category" [
  store_id: string
  catalog_category_id: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), catalog_category_id: (encode-path-segment $catalog_category_id), action_name: (encode-path-segment $action_name)} | format pattern "/v2/user/analytics/{store_id}/optimisations/bycategory/{catalog_category_id}/{action_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Optimise products by channel
#
# POST /v2/user/analytics/{storeId}/optimisations/bychannel/{channelId}/{actionName}
# operationId: OptimiseByChannel
export def "user-analytics-optimisations-bychannel create-optimise-by-channel" [
  store_id: string
  channel_id: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), channel_id: (encode-path-segment $channel_id), action_name: (encode-path-segment $action_name)} | format pattern "/v2/user/analytics/{store_id}/optimisations/bychannel/{channel_id}/{action_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimise product
#
# POST /v2/user/analytics/{storeId}/optimisations/byproduct/{productId}/{actionName}
# operationId: OptimiseByProduct
export def "user-analytics-optimisations-byproduct create-optimise-by-product" [
  store_id: string
  product_id: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), product_id: (encode-path-segment $product_id), action_name: (encode-path-segment $action_name)} | format pattern "/v2/user/analytics/{store_id}/optimisations/byproduct/{product_id}/{action_name}"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Copy product optimisations between 2 channels
#
# POST /v2/user/analytics/{storeId}/optimisations/copy
# operationId: CopyOptimisation
export def "user-analytics-optimisations-copy copy" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id_source: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  channel_id_target: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  --keep-existing-optimisation: oneof<nothing, bool> # If true the existing optimisation will be kept (e.g. false)
]: any -> record<catalogProductCount: int, channel: record<channelId: string, channelImageUrl: string, channelName: string>, enabledProductCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/optimisations/copy"))
  let req_body = {"channelIdSource": $channel_id_source, "channelIdTarget": $channel_id_target, "keepExistingOptimisation": $keep_existing_optimisation} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Optimise products by page
#
# POST /v2/user/analytics/{storeId}/optimisations/{actionName}
# operationId: Optimise
export def "user-analytics-optimisations create-optimise" [
  store_id: string
  action_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), action_name: (encode-path-segment $action_name)} | format pattern "/v2/user/analytics/{store_id}/optimisations/{action_name}"))
  let req_body = {"pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the report by category
#
# POST /v2/user/analytics/{storeId}/reports/bycategory
# operationId: GetStoreReportByCategory
export def "user-analytics-reports-bycategory get-store-by-category" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> record<categories: table<allProductCount: int, catalogCategoryId: string, catalogCategoryPath: list, catalogProductCount: int, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/reports/bycategory"))
  let req_body = {"pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the report by channel
#
# POST /v2/user/analytics/{storeId}/reports/bychannel
# operationId: GetStoreReportByChannel
export def "user-analytics-reports-bychannel get-store-by-channel" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> record<channels: table<catalogProductCount: int, channel: record, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/reports/bychannel"))
  let req_body = {"pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the report by day for a StoreId
#
# POST /v2/user/analytics/{storeId}/reports/byday
# operationId: GetStoreReportByDay
# --advancedFilters shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
export def "user-analytics-reports-byday get-store-by-day" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advanced-filters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  begin_period_utc_date: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalog-category-id: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channel-ids: list<string> # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  end_period_utc_date: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --product-id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> record<currencyCode: string, days: table<allChannels: record, byChannels: list, day: string>, globalPerformanceIndicators: record<allChannels: record<performanceIndicator: float>, byChannels: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/reports/byday"))
  let req_body = {"advancedFilters": $advanced_filters, "beginPeriodUtcDate": $begin_period_utc_date, "catalogCategoryId": $catalog_category_id, "channelIds": $channel_ids, "endPeriodUtcDate": $end_period_utc_date, "productId": $product_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the report by product
#
# POST /v2/user/analytics/{storeId}/reports/byproduct
# operationId: GetStoreReportByProduct
# --analyticsProductColumnFilters shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
export def "user-analytics-reports-byproduct get-store-by-product" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --page-size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --analytics-product-column-filters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --product-columns-to-display: list<string> # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  product_state: string@product-state-completer # You can filter on the product state. (default: All, e.g. All)
]: any -> record<currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<channelCount: int, clickCount: int, cost: float, enabledOnChannelCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, product: record, roi: float, soldProductCount: int, totalSales: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/reports/byproduct"))
  let req_body = {"pageNumber": $page_number, "pageSize": $page_size, "analyticsProductColumnFilters": $analytics_product_column_filters, "productColumnsToDisplay": $product_columns_to_display, "productState": $product_state} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get report filter list for the given store
#
# GET /v2/user/analytics/{storeId}/reports/filters
# operationId: GetReportFilters
export def "user-analytics-reports-filters list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, reportFilters: table<links: record, reportFilterId: string, reportFilterName: string, reportType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/reports/filters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the report filter
#
# DELETE /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: DeleteReportFilter
export def "user-analytics-reports-filters delete" [
  store_id: string
  report_filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), report_filter_id: (encode-path-segment $report_filter_id)} | format pattern "/v2/user/analytics/{store_id}/reports/filters/{report_filter_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the report filter description
#
# GET /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: GetReportFilter
export def "user-analytics-reports-filters get" [
  store_id: string
  report_filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, parameters: record<advancedFilters: record<globalMarginPercent: int, linkClickToOrderMaxDay: int, linkClickToOrderType: string, marginType: string, onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record>, beginPeriodUtcDate: string, categoryFilter: record<categoryPath: list>, channelId: string, endPeriodUtcDate: string, performanceIndicatorFilters: list<record>, periodType: string, analyticsProductColumnFilters: record<additionalAnalyticsProductColumnFilters: record, sku: string, title: string>, productColumnsToDisplay: list<string>, productState: string, reportType: string>, reportFilterId: string, reportFilterName: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), report_filter_id: (encode-path-segment $report_filter_id)} | format pattern "/v2/user/analytics/{store_id}/reports/filters/{report_filter_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save the report filter
#
# PUT /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: SaveReportFilter
export def "user-analytics-reports-filters update-save" [
  store_id: string
  report_filter_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  parameters: any
  report_filter_name: string # Report filter name (e.g. My report filter)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), report_filter_id: (encode-path-segment $report_filter_id)} | format pattern "/v2/user/analytics/{store_id}/reports/filters/{report_filter_id}"))
  let req_body = {"parameters": $parameters, "reportFilterName": $report_filter_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Gets the list of rules for a given store
#
# GET /v2/user/analytics/{storeId}/rules
# operationId: GetRules
export def "user-analytics-rules list" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, rules: table<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/rules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rule creation
#
# POST /v2/user/analytics/{storeId}/rules
# operationId: CreateRule
export def "user-analytics-rules create" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-utc-date: string # The end validity utc date of the rule (format: date-time, e.g. 2017-09-30T10:42:40.001Z)
  optimisation_action_name: string@optimisation-action-name-completer # The optimisation action (e.g. reenable)
  report_filter_id: string # The report filter to use for the rule (format: guid, e.g. fb19c53c-2f63-4262-9d94-2d7faa500acd)
  rule_name: string # The name of the rule (e.g. My rule)
  --start-utc-date: string # The start validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/rules"))
  let req_body = {"endUtcDate": $end_utc_date, "optimisationActionName": $optimisation_action_name, "reportFilterId": $report_filter_id, "ruleName": $rule_name, "startUtcDate": $start_utc_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the rules execution history
#
# GET /v2/user/analytics/{storeId}/rules/executions
# operationId: GetRulesExecutions
export def "user-analytics-rules-executions get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page to retrieve (default: 1)
  --page-size: int # The count of rule history to retrieve (default: 10)
]: nothing -> record<executions: table<activeAffectedProductCount: int, affectedChannelCount: int, affectedProductCount: int, completedUtcDate: string, errorType: string, executionSource: string, links: record, optimisationActionName: string, reportUrl: string, ruleId: string, ruleName: string, startedUtcDate: string, status: string, userId: string>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/rules/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run all rules for this store
#
# POST /v2/user/analytics/{storeId}/rules/run
# operationId: RunRules
export def "user-analytics-rules-run create-by-storeId" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/rules/run"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Rule
#
# DELETE /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: DeleteRule
export def "user-analytics-rules delete" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the rule
#
# GET /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: GetRule
export def "user-analytics-rules get" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<actionName: string, enabled: bool, lastExecutionStatus: string, lastExecutionUtcDate: string, links: record<delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, movedown: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, moveup: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reportFilter: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, run: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, update: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, position: int, reportFilterId: string, ruleId: string, ruleName: string, validityEndUtcDate: string, validityStartUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Rule
#
# PATCH /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: UpdateRule
export def "user-analytics-rules update" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --end-utc-date: string # Not required. The end validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
  rule_name: string # The name of the rule (e.g. My Rule Renamed)
  --start-utc-date: string # Not required. The start validity utc date of the rule. (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}"))
  let req_body = {"endUtcDate": $end_utc_date, "ruleName": $rule_name, "startUtcDate": $start_utc_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/disable
# operationId: DisableRule
export def "user-analytics-rules-disable disable" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/enable
# operationId: EnableRule
export def "user-analytics-rules-enable enable" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move the rule down
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/movedown
# operationId: MoveDownRule
export def "user-analytics-rules-movedown move-down" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}/movedown"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move the rule up
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/moveup
# operationId: MoveUpRule
export def "user-analytics-rules-moveup move-up" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}/moveup"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/run
# operationId: RunRule
export def "user-analytics-rules-run create-by-storeId-ruleId" [
  store_id: string
  rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), rule_id: (encode-path-segment $rule_id)} | format pattern "/v2/user/analytics/{store_id}/rules/{rule_id}/run"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked clicks
#
# GET /v2/user/analytics/{storeId}/tracking/clicks
# operationId: GetStoreTrackedClicks
export def "user-analytics-tracking-clicks get-store-tracked" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of clicks to retrieve (default: 100)
]: nothing -> record<clicks: table<channel: record, ipAddress: string, product: record, utcDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/tracking/clicks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked external orders
#
# GET /v2/user/analytics/{storeId}/tracking/externalorders
# operationId: GetStoreTrackedExternalOrders
export def "user-analytics-tracking-externalorders get-store-tracked-external-orders" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of external orders to retrieve (default: 100)
]: nothing -> record<externalOrders: table<currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string, visitorId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/tracking/externalorders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked orders
#
# GET /v2/user/analytics/{storeId}/tracking/orders
# operationId: GetStoreTrackedOrders
export def "user-analytics-tracking-orders get-store-tracked" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --count: int # The amount of orders to retrieve (default: 100)
]: nothing -> record<orders: table<channel: record, currencyCode: string, merchantOrderId: string, paymentValidated: bool, products: list, totalAmount: float, utcDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "count" $count "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/tracking/orders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the synchronization status of clicks and orders of a store
#
# GET /v2/user/analytics/{storeId}/tracking/status
# operationId: GetStoreTrackingStatus
export def "user-analytics-tracking-status get-store" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<clickSynchronizationUtcDate: string, marketplaceOrderSynchonizationUtcDate: string, orderSynchonizationUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/analytics/{store_id}/tracking/status"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the index of the catalog API
#
# GET /v2/user/catalogs/
# operationId: CatalogIndex
export def "user-catalogs get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<beezUPColumnDataTypeLov: record<href: string, method: string>, beezUPColumnDisplayGroupLov: record<href: string, method: string>, beezUPColumnImportanceLov: record<href: string, method: string>, beezUPColumnLov: record<href: string, method: string>, compareOptionLov: record<href: string, method: string>, duplicateProductValueStrategyLov: record<href: string, method: string>>, storeLinks: record<links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/catalogs/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the BeezUP columns
#
# GET /v2/user/catalogs/beezupColumns
# operationId: Catalog_GetBeezUPColumns
export def "user-catalogs-beezup-columns get-beez-up" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<beezUPColumnName: string, canBeTruncated: bool, columnDataType: string, columnImportance: string, description: string, displayGroupName: string, unique: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/catalogs/beezupColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest catalog importation reporting for all your stores
#
# GET /v2/user/catalogs/importations
# operationId: Importation_GetReportingsAllStores
export def "user-catalogs-importations get-reportings-list-stores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/catalogs/importations")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the index of the catalog API for this store
#
# GET /v2/user/catalogs/{storeId}
# operationId: CatalogStoreIndex
export def "user-catalogs get-store-index" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<autoImportInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, categories: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, computeExpression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, importations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, inputConfiguration: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, randomProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, startImportation: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Auto Import
#
# DELETE /v2/user/catalogs/{storeId}/autoImport
# operationId: Auto_DeleteAutoImport
export def "user-catalogs-auto-import delete" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto import configuration
#
# GET /v2/user/catalogs/{storeId}/autoImport
# operationId: Auto_GetAutoImportConfiguration
export def "user-catalogs-auto-import get-configuration" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<duplicateProductConfiguration: record<compareOptions: string, strategy: string>, input: record<files: list<record>, transformFileUrl: string>, inputConfiguredByUserId: string, pauseStatusChangedByUserId: string, pauseStatusChangedUtcDate: string, paused: bool, scheduledByUserId: string, schedulingLocalTimeZoneName: string, schedulingType: string, schedulingValue: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate the auto importation of the last successful manual catalog importation.
#
# POST /v2/user/catalogs/{storeId}/autoImport/activate
# operationId: Importation_ActivateAutoImport
export def "user-catalogs-auto-import-activate import-importation" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/activate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/pause
# operationId: Auto_PauseAutoImport
export def "user-catalogs-auto-import-pause pause" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/pause"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/resume
# operationId: Auto_ResumeAutoImport
export def "user-catalogs-auto-import-resume import" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/resume"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure Auto Import Interval
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/interval
# operationId: Auto_ConfigureAutoImportInterval
export def "user-catalogs-auto-import-scheduling-interval import-configure" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  interval: string # Indicate the interval in time span. (i.e. "04:00:00" for every 4 hours) (e.g. 04:00:00)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/scheduling/interval"))
  let req_body = {"interval": $interval} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Configure Auto Import Schedules
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/schedules
# operationId: Auto_ScheduleAutoImport
export def "user-catalogs-auto-import-scheduling-schedules import" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --local-time-zone-name: string # If null the local time zone name will be "Romance Standard Time" (default: Romance Standard Time, e.g. Romance Standard Time)
  schedules: list<string> # Indicate the time span you want to import your catalog. (i.e. "21:00:00" to import your catalog at 9PM) (e.g. [21:00:00, 23:00:00, 08:30:00])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/scheduling/schedules"))
  let req_body = {"localTimeZoneName": $local_time_zone_name, "schedules": $schedules} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Start Auto Import Manually
#
# POST /v2/user/catalogs/{storeId}/autoImport/start
# operationId: Auto_StartAutoImport
export def "user-catalogs-auto-import-start start" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/autoImport/start"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get catalog column list
#
# GET /v2/user/catalogs/{storeId}/catalogColumns
# operationId: Catalog_GetCatalogColumns
export def "user-catalogs-catalog-columns get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<catalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/catalogColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change Catalog Column User Name
#
# POST /v2/user/catalogs/{storeId}/catalogColumns/{columnId}/rename
# operationId: Catalog_ChangeCatalogColumnUserName
export def "user-catalogs-catalog-columns-rename create-change-name" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/catalogColumns/{column_id}/rename"))
  let req_body = {"userColumName": $user_colum_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get category list
#
# GET /v2/user/catalogs/{storeId}/categories
# operationId: Catalog_GetCategories
export def "user-catalogs-categories get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size.
]: nothing -> record<categories: table<categoryId: string, categoryPath: list, selfProductCount: int, totalProductCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom column list
#
# GET /v2/user/catalogs/{storeId}/customColumns
# operationId: Catalog_GetCustomColumns
export def "user-catalogs-custom-columns get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customColumns: table<catalogColumnDependencies: list, configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compute the expression for this catalog.
#
# POST /v2/user/catalogs/{storeId}/customColumns/computeExpression
# operationId: Catalog_ComputeExpression
export def "user-catalogs-custom-columns-compute-expression create" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  product_values: record # The key is the column identifier (e.g. {012929c0-e78b-462a-a96e-25c061575385: http://media.conforama.fr/Medias/500000/80000/5000/500/10/G_585511_A.jpg, 46602e10-bc45-4944-a440-63d5f7ece1f8: 42, 68082b11-4ffd-4bec-964a-465a471c7d37: SKU1234, b6d74510-41ce-42ec-947a-0bdf62e9beee: Refrigerateur, ba270fa0-8482-46be-905a-cae4ca746b92: http://www.conforama.fr/gros-electromenager/encastrable/refrigerateur-encastrable/refrigerateur-combine-161-litres-far-r5115s/p/585511})
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/computeExpression"))
  let req_body = {"encryptedExpression": $encrypted_expression, "productValues": $product_values} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete custom column
#
# DELETE /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_DeleteCustomColumn
export def "user-catalogs-custom-columns delete" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/{column_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_SaveCustomColumn
export def "user-catalogs-custom-columns update-save" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  display_group_name: string # Indicate the display group name where the column must be putted (e.g. Category)
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  user_column_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/{column_id}"))
  let req_body = {"displayGroupName": $display_group_name, "encryptedBlocklyExpression": $encrypted_blockly_expression, "encryptedExpression": $encrypted_expression, "userColumnName": $user_column_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the encrypted custom column expression
#
# GET /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# operationId: Catalog_GetCustomColumnExpression
export def "user-catalogs-custom-columns-expression get" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/{column_id}/expression"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change custom column expression
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# operationId: Catalog_ChangeCustomColumnExpression
export def "user-catalogs-custom-columns-expression update-change" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/{column_id}/expression"))
  let req_body = {"encryptedBlocklyExpression": $encrypted_blockly_expression, "encryptedExpression": $encrypted_expression} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change Custom Column User Name
#
# POST /v2/user/catalogs/{storeId}/customColumns/{columnId}/rename
# operationId: Catalog_ChangeCustomColumnUserName
export def "user-catalogs-custom-columns-rename create-change-name" [
  store_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/customColumns/{column_id}/rename"))
  let req_body = {"userColumName": $user_colum_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the latest catalog importation reporting
#
# GET /v2/user/catalogs/{storeId}/importations
# operationId: Importation_GetReportings
export def "user-catalogs-importations get-reportings" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<importations: table<autoImported: bool, beginUtcDate: string, endUtcDate: string, errors: list, executionId: string, inputConfigurationUrl: string, lastUpdateUtcDate: string, links: record, stepName: string, steps: record, success: bool, totalProductCount: int, totalProductErrorCount: int, totalProductSuccessCount: int, userId: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, start: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/importations"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Manual Import
#
# POST /v2/user/catalogs/{storeId}/importations/start
# operationId: Importation_StartManualUpdate
# --duplicateProductSkuConfiguration shape: {compareOptions: "None"|"IgnoreCase"|"IgnoreNonSpace"|"IgnoreSymbols"|"OrdinalIgnoreCase"|"StringSort"|"Ordinal", strategy: "None"|"SkipAllDuplicateProducts"|"KeepFirstDuplicateProductOnly"|"FailImportationIfAnyDuplicateProduct"}
# --input shape: {files: list, transformFileUrl?: string}
export def "user-catalogs-importations-start update-manual" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --duplicate-product-sku-configuration: record # Describe how you want to manage the duplication of the product value — shape: {compareOptions: "None"|"IgnoreCase"|"IgnoreNonSpace"|"IgnoreSymbols"|"OrdinalIgnoreCase"|"StringSort"|"Ordinal", strategy: "None"|"SkipAllDuplicateProducts"|"KeepFirstDuplicateProductOnly"|"FailImportationIfAnyDuplicateProduct"}
  input: record # Describe the input configuration — shape: {files: list, transformFileUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/start"))
  let req_body = {"duplicateProductSkuConfiguration": $duplicate_product_sku_configuration, "input": $input} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the importation status
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}
# operationId: Importation_GetImportationMonitoring
export def "user-catalogs-importations get-monitoring" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<beginUtcDate: string, errors: table<arguments: list, code: string, cultureName: string, docUrl: string, message: string>, executionId: string, lastUpdateUtcDate: string, links: record<activateAutoImport: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, cancel: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, catalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commit: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, commitColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureRemainingCatalogColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, customColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, productSamples: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, technicalProgression: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, steps: record, success: bool, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/cancel
# operationId: Importation_Cancel
export def "user-catalogs-importations-cancel cancel" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/cancel"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detected catalog columns during this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns
# operationId: Importation_GetDetectedCatalogColumns
export def "user-catalogs-importations-catalog-columns get-detected" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<detectedCatalogColumns: table<catalogColumnName: string, configuration: record, duplicateProductValueConfiguration: record, id: string, ignored: bool, links: record, userColumName: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}
# operationId: Importation_ConfigureCatalogColumn
# --catalogColumn shape: {catalogColumnName: string, configuration: record, duplicateProductValueConfiguration?: record, id: string, ignored?: bool, links: record, userColumName: string}
export def "user-catalogs-importations-catalog-columns create-configure" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  catalog_column: record # The catalog column configuration (e.g. {catalogColumnName: SKU, configuration: {beezUPColumnName: CategoryFirstLevel, canBeTruncated: false, columnCultureName: fr-FR, columnDataType: String, columnFormat: MM/dd/yyyy, columnImportance: Required, displayGroupName: Category}, duplicateProductValueConfiguration: {compareOptions: IgnoreCase, strategy: KeepFirstDuplicateProductOnly}, id: 8a76f06a-fefc-4c0d-bcfe-b210f1482977, ignored: true, userColumName: My SKU}) — shape: {catalogColumnName: string, configuration: record, duplicateProductValueConfiguration?: record, id: string, ignored?: bool, links: record, userColumName: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns/{column_id}"))
  let req_body = {"catalogColumn": $catalog_column} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Ignore Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/ignore
# operationId: Importation_IgnoreColumn
export def "user-catalogs-importations-catalog-columns-ignore create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns/{column_id}/ignore"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Map catalog column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/map
# operationId: Importation_MapCatalogColumn
export def "user-catalogs-importations-catalog-columns-map create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_column_name: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns/{column_id}/map"))
  let req_body = {"beezUPColumnName": $beez_up_column_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reattend Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/reattend
# operationId: Importation_ReattendColumn
export def "user-catalogs-importations-catalog-columns-reattend create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns/{column_id}/reattend"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unmap catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/unmap
# operationId: Importation_UnmapCatalogColumn
export def "user-catalogs-importations-catalog-columns-unmap create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/catalogColumns/{column_id}/unmap"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit Importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commit
# operationId: Importation_Commit
export def "user-catalogs-importations-commit commit" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/commit"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commitColumns
# operationId: Importation_CommitColumns
export def "user-catalogs-importations-commit-columns commit" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/commitColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure remaining catalog columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/configureRemainingCatalogColumns
# operationId: Importation_ConfigureRemainingCatalogColumns
export def "user-catalogs-importations-configure-remaining-catalog-columns create" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/configureRemainingCatalogColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom columns currently place in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns
# operationId: Importation_GetCustomColumns
export def "user-catalogs-importations-custom-columns get" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<customColumns: table<configuration: record, id: string, links: record, userColumName: string>, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Custom Column
#
# DELETE /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_DeleteCustomColumn
export def "user-catalogs-importations-custom-columns delete" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns/{column_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_SaveCustomColumn
export def "user-catalogs-importations-custom-columns update-save" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encrypted_blockly_expression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encrypted_expression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  user_colum_name: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns/{column_id}"))
  let req_body = {"encryptedBlocklyExpression": $encrypted_blockly_expression, "encryptedExpression": $encrypted_expression, "userColumName": $user_colum_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the encrypted custom column expression in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/expression
# operationId: Importation_GetCustomColumnExpression
export def "user-catalogs-importations-custom-columns-expression get" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns/{column_id}/expression"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Map custom column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/map
# operationId: Importation_MapCustomColumn
export def "user-catalogs-importations-custom-columns-map create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_column_name: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns/{column_id}/map"))
  let req_body = {"beezUPColumnName": $beez_up_column_name} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Unmap custom column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/unmap
# operationId: Importation_UnmapCustomColumn
export def "user-catalogs-importations-custom-columns-unmap create" [
  store_id: string
  execution_id: string
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/customColumns/{column_id}/unmap"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the product sample related to this importation with all columns (catalog and custom)
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}
# operationId: Importation_GetProductSample
export def "user-catalogs-importations-product-samples get" [
  store_id: string
  execution_id: string
  product_sample_index: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<productValues: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), product_sample_index: (encode-path-segment $product_sample_index)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/productSamples/{product_sample_index}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product sample custom column value related to this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}/customColumns/{columnId}
# operationId: Importation_GetProductSampleCustomColumnValue
export def "user-catalogs-importations-product-samples-custom-columns get-value" [
  store_id: string
  execution_id: string
  product_sample_index: int
  column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id), product_sample_index: (encode-path-segment $product_sample_index), column_id: (encode-path-segment $column_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/productSamples/{product_sample_index}/customColumns/{column_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Importation Get Products Report
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/products/list
# operationId: Importation_GetProductsReport
# --errorCodes item shape: {errorCode?: string, userColumnName?: string}
export def "user-catalogs-importations-products-list get-report" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ean: string # Filter by EAN (equals)
  --error-codes: list # Get Importation Products Report Request Error Codes — item shape: {errorCode?: string, userColumnName?: string}
  --mpn: string # Filter by MPN (equals)
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --sku: string # Filter by Sku (equals)
  --title: string # Filter by Title (StartsWith)
]: any -> record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productErrors: table<ean: string, errors: list, lineNumber: int, mpn: string, sku: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/products/list"))
  let req_body = {"ean": $ean, "errorCodes": $error_codes, "mpn": $mpn, "pageNumber": $page_number, "pageSize": $page_size, "sku": $sku, "title": $title} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Importation Get Report
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/report
# operationId: Importation_GetReport
export def "user-catalogs-importations-report get" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categories: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, columns: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>, errors: table<beezUPColumnName: string, errorCode: string, productCount: int, userColumName: string>, executionId: string, importationInfo: record<beginUtcDate: string, endUtcDate: string, inputConfiguration: record<fetch: record, fileNumber: int, read: record>, userId: string>, productMetrics: record<activeCount: int, detectedCount: int, duplicatedCount: int, failedCount: int>, products: record<createdCount: int, deletedCount: int, unchangedCount: int, updatedCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/report"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get technical progression
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/technicalProgression
# operationId: Importation_TechnicalProgression
export def "user-catalogs-importations-technical-progression get" [
  store_id: string
  execution_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<stepsProgression: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), execution_id: (encode-path-segment $execution_id)} | format pattern "/v2/user/catalogs/{store_id}/importations/{execution_id}/technicalProgression"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the last input configuration
#
# GET /v2/user/catalogs/{storeId}/inputConfiguration
# operationId: Importation_GetManualUpdateLastInputConfig
export def "user-catalogs-input-configuration get-importation-manual-update-last-config" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<input: record<files: list<record>, transformFileUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/inputConfiguration"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product by Sku
#
# GET /v2/user/catalogs/{storeId}/products
# operationId: Catalog_GetProductBySku
export def "user-catalogs-products get-by-sku" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --sku: string # The product sku you want to get
]: nothing -> record<categoryId: string, exists: bool, productId: string, values: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "sku" $sku "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/products") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product list
#
# POST /v2/user/catalogs/{storeId}/products/list
# operationId: Catalog_GetProducts
export def "user-catalogs-products-list get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-path: list<string> # The catalog category path (e.g. [Vêtements, Femmes, Chaussures])
  --column-id-list: list<string>
  --ean: string # Search for product by ean (e.g. MySku123)
  --exists: oneof<nothing, bool> # Search for existing products or not. If null you will received both. (e.g. true)
  --mpn: string # Search for product by mpn (e.g. MySku123)
  --order-by-catalog-column-id: string # The catalog column identifier (catalog or custom column) (format: guid, e.g. bea7c21e-948b-4ac3-9ffd-4396e62c4163)
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --product-id-list: list<string> # Filter with a list of product identifier
  --sku: string # Search for product by sku (e.g. MySku123)
  --title: string # Search for products containing this title (e.g. Frigo)
  --without-sub-categories: oneof<nothing, bool> # Do not retrieve sub categories. By default, this value is set to false (e.g. false)
]: any -> record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<categoryId: string, exists: bool, productId: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/products/list"))
  let req_body = {"categoryPath": $category_path, "columnIdList": $column_id_list, "ean": $ean, "exists": $exists, "mpn": $mpn, "orderByCatalogColumnId": $order_by_catalog_column_id, "pageNumber": $page_number, "pageSize": $page_size, "productIdList": $product_id_list, "sku": $sku, "title": $title, "withoutSubCategories": $without_sub_categories} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get random product list
#
# GET /v2/user/catalogs/{storeId}/products/random
# operationId: Catalog_GetRandomProducts
export def "user-catalogs-products-random get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<products: table<categoryId: string, exists: bool, productId: string, values: record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/catalogs/{store_id}/products/random"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product by ProductId
#
# GET /v2/user/catalogs/{storeId}/products/{productId}
# operationId: Catalog_GetProductByProductId
export def "user-catalogs-products get" [
  store_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<categoryId: string, exists: bool, productId: string, values: record> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/catalogs/{store_id}/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all your current channel catalogs
#
# GET /v2/user/channelCatalogs/
# operationId: GetChannelCatalogs
export def "user-channel-catalogs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<channelCatalogs: record, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, filterOperators: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<channelCatalogExclusionFilterOperatorLov: record<href: string, method: string>, channelCatalogExportCacheStatusLov: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/channelCatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new channel catalog
#
# POST /v2/user/channelCatalogs/
# operationId: AddChannelCatalog
export def "user-channel-catalogs create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_id: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/channelCatalogs/")
  let req_body = {"channelId": $channel_id, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get channel catalog filter operators
#
# GET /v2/user/channelCatalogs/filterOperators
# operationId: GetChannelCatalogFilterOperators
export def "user-channel-catalogs-filter-operators get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<expectedChannelColumnDataType: string, expectedValueDataType: string, name: string, valueRequired: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/channelCatalogs/filterOperators")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog products related to these channel catalogs
#
# POST /v2/user/channelCatalogs/products
# operationId: GetChannelCatalogProductByChannelCatalog
export def "user-channel-catalogs-products get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_catalog_ids: list<string> # The list of channel catalog identifier
  product_id: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> record<channelCatalogs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/channelCatalogs/products")
  let req_body = {"channelCatalogIds": $channel_catalog_ids, "productId": $product_id, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete the channel catalog
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}
# operationId: DeleteChannelCatalog
export def "user-channel-catalogs delete" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the channel catalog information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}
# operationId: GetChannelCatalog
export def "user-channel-catalogs get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channelId: string, channelImageUrl: string, channelName: string, categoryMappingSettings: record<categoryMappingDisabledByMerchant: bool>, channelCatalogId: string, channelCategorySettings: record<mappingLeafRequired: bool, mappingRequired: bool>, channelCostSettings: record<costType: string, globalCostValue: float>, columnMappings: table<catalogColumnId: string, channelCategoryPath: list, channelColumnId: string, catalogBeezUPColumnName: string, catalogColumnName: string, channelBeezUPColumnName: string, channelColumnName: string>, costSettings: record<costType: string, globalCostValue: float>, enabled: bool, exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, exportUrl: string, generalSettings: record<acceptToPublishInfo: bool, activeBeezUPTracking: bool, doNotExportOutOfStockProducts: bool>, isMarketplace: bool, links: record<categoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureColumnMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureCostSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, configureGeneralSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exclusionFilters: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportationCacheInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, marketplaceSettings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, products: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenableCategoryMappings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, state: record<apiSettingsStatus: string, categoryMappingState: record<status: string, uncategorizedProductCount: int, withoutCategoryCostProductCount: int>, columnMappingStatus: string, exportedProductCount: int>, storeId: string, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog categories
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/categories
# operationId: GetChannelCatalogCategories
export def "user-channel-catalogs-categories get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<channelCatalogCategoryConfigurations: table<catalogCategoryPath: list, channelCategoryPath: list, costValue: float, links: record>, costStatus: string, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, mappingStatus: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog category
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/configure
# operationId: ConfigureChannelCatalogCategory
# --channelCatalogCategories item shape: {autoMapNewSubCategories: bool, catalogCategoryPath: list<string>, channelCategoryPath?: list<string>, costValue?: float}
export def "user-channel-catalogs-categories-configure create-category" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channel_catalog_categories: list # item shape: {autoMapNewSubCategories: bool, catalogCategoryPath: list<string>, channelCategoryPath?: list<string>, costValue?: float}
  --override-sub-category-mappings: oneof<nothing, bool> # Great feature! In case of mapping to parent channel category, you can ask to override the mapping of all sub channel category to this catalog category path (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/categories/configure"))
  let req_body = {"channelCatalogCategories": $channel_catalog_categories, "overrideSubCategoryMappings": $override_sub_category_mappings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/disableMapping
# operationId: DisableChannelCatalogCategoryMapping
export def "user-channel-catalogs-categories-disable-mapping disable-category" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/categories/disableMapping"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reenable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/reenableMapping
# operationId: ReenableChannelCatalogCategoryMapping
export def "user-channel-catalogs-categories-reenable-mapping create-category" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/categories/reenableMapping"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog column mappings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/columnMappings
# operationId: ConfigureChannelCatalogColumnMappings
export def "user-channel-catalogs-column-mappings update-configure" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/columnMappings"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Disable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/disable
# operationId: DisableChannelCatalog
export def "user-channel-catalogs-disable disable" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/enable
# operationId: EnableChannelCatalog
export def "user-channel-catalogs-enable enable" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/enable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog exclusion filters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# operationId: GetChannelCatalogExclusionFilters
export def "user-channel-catalogs-exclusion-filters get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<exclusionFilters: table<channelColumnId: string, enabled: bool, groupId: string, name: string, operatorName: string, position: int, positionInGroup: int, value: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/exclusionFilters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog exclusion filters
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# operationId: ConfigureChannelCatalogExclusionFilters
export def "user-channel-catalogs-exclusion-filters update-configure" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/exclusionFilters"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the exportation cache information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache
# operationId: GetChannelCatalogExportationCacheInfo
export def "user-channel-catalogs-exportations-cache get-get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cacheInfo: record<cacheStatus: string, expirationUtcDate: string, feedUrl: string, lastContentChangeUtcDate: string, lastUpdateUtcDate: string>, links: record<clear: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/exportations/cache"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear the exportation cache
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache/clear
# operationId: ClearChannelCatalogExportationCache
export def "user-channel-catalogs-exportations-cache-clear create" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/exportations/cache/clear"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the exportation history
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/history
# operationId: GetChannelCatalogExportationHistory
export def "user-channel-catalogs-exportations-history get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number you want to get (format: int32, e.g. 1)
  --page-size: int # The entry count you want to get (format: int32, e.g. 25)
]: nothing -> record<exportations: table<cacheStatus: string, clientIpAddress: string, clientUserAgent: string, exportationDuration: string, exportationUtcDate: string, exportedProductCount: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/exportations/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products
# operationId: GetChannelCatalogProductInfoList
# --catalogCategoryFilter shape: {categoryPath?: list<string>}
# --channelCategoryFilter shape: {categoryPath?: list<string>}
# --criteria shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
# --productFilters shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
export def "user-channel-catalogs-products get-get-list" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalog-category-filter: record # shape: {categoryPath?: list<string>}
  --channel-category-filter: record # shape: {categoryPath?: list<string>}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  page_number: int # format: int32, e.g. 1
  page_size: int # format: int32, e.g. 100
  --product-filters: record # shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
]: any -> record<links: record<export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productInfos: table<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list, links: record, overrides: record, uncategorized: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products"))
  let req_body = {"catalogCategoryFilter": $catalog_category_filter, "channelCategoryFilter": $channel_category_filter, "criteria": $criteria, "overridden": $overridden, "pageNumber": $page_number, "pageSize": $page_size, "productFilters": $product_filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get channel catalog products' counters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/counters
# operationId: GetChannelCatalogProductsCounters
export def "user-channel-catalogs-products-counters get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<disabledProductCountExcludingUncategorized: int, disabledProductCountIncludingUncategorized: int, excludedProductCountExcludingUncategorizedAndDisabled: int, excludedProductCountIncludingUncategorizedAndDisabled: int, existingProductCount: int, uncategorizedProductCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/counters"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/export
# operationId: ExportChannelCatalogProductInfoList
# --catalogCategoryFilter shape: {categoryPath?: list<string>}
# --channelCategoryFilter shape: {categoryPath?: list<string>}
# --criteria shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
# --productFilters shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
export def "user-channel-catalogs-products-export get-list" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The file type of the exportation
  --catalog-category-filter: record # shape: {categoryPath?: list<string>}
  --channel-category-filter: record # shape: {categoryPath?: list<string>}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  page_number: int # format: int32, e.g. 1
  page_size: int # format: int32, e.g. 100
  --product-filters: record # shape: {additionalProductFilters?: record, catalogEans?: list<string>, catalogMpns?: list<string>, catalogSkus?: list<string>, channelEans?: list<string>, channelMpns?: list<string>, channelSkus?: list<string>, title?: string}
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/export") $qp)
  let req_body = {"catalogCategoryFilter": $catalog_category_filter, "channelCategoryFilter": $channel_category_filter, "criteria": $criteria, "overridden": $overridden, "pageNumber": $page_number, "pageSize": $page_size, "productFilters": $product_filters} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get channel catalog product information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}
# operationId: GetChannelCatalogProductInfo
export def "user-channel-catalogs-products get-get" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list<string>, links: record<disable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, override: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, reenable: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, overrides: record, uncategorized: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/disable
# operationId: DisableChannelCatalogProduct
export def "user-channel-catalogs-products-disable disable" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/disable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Override channel catalog product values
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides
# operationId: OverrideChannelCatalogProductValues
export def "user-channel-catalogs-products-overrides update-values" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/overrides"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get channel catalog product value override compatibilities status
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: GetChannelCatalogProductValueOverrideCopy
export def "user-channel-catalogs-products-overrides-copy get-value" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/overrides/copy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy channel catalog product value override
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: ConfigureChannelCatalogProductValueOverrideCopy
export def "user-channel-catalogs-products-overrides-copy copy-configure-value" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/overrides/copy"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific channel catalog product value override
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/{channelColumnId}
# operationId: DeleteChannelCatalogProductValueOverride
export def "user-channel-catalogs-products-overrides delete-value" [
  channel_catalog_id: string
  product_id: string
  channel_column_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id), channel_column_id: (encode-path-segment $channel_column_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/overrides/{channel_column_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reenable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/reenable
# operationId: ReenableChannelCatalogProduct
export def "user-channel-catalogs-products-reenable create" [
  channel_catalog_id: string
  product_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id), product_id: (encode-path-segment $product_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/products/{product_id}/reenable"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog cost settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/cost
# operationId: ConfigureChannelCatalogCostSettings
export def "user-channel-catalogs-settings-cost update-configure" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cost_type: string@cost-type-completer # CPC means cost per click. CPA means cost per action. You can have CPC/CPA with a global cost value. You can have CPC/CPA by category the cost value MUST be null You can have global fixed price. (e.g. Fixed_Global)
  --global-cost-value: float # In case of global cost type, you have to indicate the cost value. (format: decimal, e.g. 10.21)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/settings/cost"))
  let req_body = {"costType": $cost_type, "globalCostValue": $global_cost_value} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Configure channel catalog general settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/general
# operationId: ConfigureChannelCatalogGeneralSettings
export def "user-channel-catalogs-settings-general update-configure" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-to-publish-info: oneof<nothing, bool> # If true then you authorize disclosure of my statistics generated from clicks and sales (e.g. true)
  --active-beez-up-tracking: oneof<nothing, bool> # Activate BeezUP tracking for my statistics (checked by default) (default: true, e.g. true)
  --do-not-export-out-of-stock-products: oneof<nothing, bool> # Do not export "out of stock" products. Note: this option is not taken into account by the counter. (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/channelCatalogs/{channel_catalog_id}/settings/general"))
  let req_body = {"acceptToPublishInfo": $accept_to_publish_info, "activeBeezUPTracking": $active_beez_up_tracking, "doNotExportOutOfStockProducts": $do_not_export_out_of_stock_products} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# List all available channel for this store
#
# GET /v2/user/channels/
# operationId: GetAvailableChannels
export def "user-channels get-available" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> table<channelId: string, channelLogoUrl: string, channelName: string, links: record<self: record>, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/channels/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel information
#
# GET /v2/user/channels/{channelId}
# operationId: GetChannelInfo
export def "user-channels get-get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<beezUPOffer: string, channelDescription: string, channelId: string, channelLogoUrl: string, channelName: string, details: record<businessModel: string, category: string, channelType: string, costs: string, homeUrl: string, subscriptionLink: string, trackingType: string>, keyNumbers: record<categories: string, products: string, stores: string, viewsPerMonth: string>, salesContact: record<email: string, name: string, phoneNumber: string>, technicalContact: record<email: string, name: string, phoneNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/user/channels/{channel_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel categories
#
# GET /v2/user/channels/{channelId}/categories
# operationId: GetChannelCategories
export def "user-channels-categories get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size.
]: nothing -> record<firstLevelCategories: table<channelCategoryChannelCode: string, channelCategoryColumnOverrides: record, channelCategoryDefaultCost: float, channelCategoryId: string, channelCategoryLevel: int, channelCategoryName: string, subCategories: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/user/channels/{channel_id}/categories"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel columns
#
# POST /v2/user/channels/{channelId}/columns
# operationId: GetChannelColumns
export def "user-channels-columns get" [
  channel_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Indicates that the client accepts that the response will be compressed to reduce traffic size.
  --body: record
]: any -> table<channelColumnDescription: string, channelColumnId: string, channelColumnName: string, configuration: record<beezUPColumnName: string, columnDataType: string, columnImportance: string>, position: int, restrictedValues: record, showInMapping: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_id: (encode-path-segment $channel_id)} | format pattern "/v2/user/channels/{channel_id}/columns"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# The index of all operations and LOV
#
# GET /v2/user/customer/
# operationId: GetCustomerIndex
export def "user-customer get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<accountInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, billingPeriods: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, friendInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getOffer: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, invoices: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, logout: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, standardOffers: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, stores: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<activeOfferLov: record<href: string, method: string>, beezUPTimeZoneLov: record<href: string, method: string>, contractTerminationReasonLov: record<href: string, method: string>, countryLov: record<href: string, method: string>, customerStatusLov: record<href: string, method: string>, invoicePaymentStatusLov: record<href: string, method: string>, offerLov: record<href: string, method: string>, storeCountryLov: record<href: string, method: string>, storeSectorLov: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user account information
#
# GET /v2/user/customer/account
# operationId: GetUserAccountInfo
export def "user-customer-account get-get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<commercialOwnerEmail: string, companyInfo: record<accountingEmails: list<string>, address: string, city: string, company: string, countryIsoCodeAlpha3: string, postalCode: string, vatNumber: string>, email: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<activateUserAccount: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changeEmail: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changePassword: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCompanyInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, savePersonalInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, personalInfo: record<beezUPTimeZoneId: int, firstName: string, lastName: string, phoneNumber: string, whatIDo: string>, profilePictureUrl: string, status: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate the user account
#
# POST /v2/user/customer/account/activate
# operationId: ActivateUserAccount
export def "user-customer-account-activate create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/activate")
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change user email
#
# POST /v2/user/customer/account/changeEmail
# operationId: ChangeEmail
export def "user-customer-account-change-email create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_email: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/changeEmail")
  let req_body = {"newEmail": $new_email} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change user password
#
# POST /v2/user/customer/account/changePassword
# operationId: ChangePassword
export def "user-customer-account-change-password create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  new_password: string # Your new password. Which must respect the same constraints as the user registeration (format: password)
  old_password: string # Your current password (format: password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/changePassword")
  let req_body = {"newPassword": $new_password, "oldPassword": $old_password} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Change company information
#
# PUT /v2/user/customer/account/companyInfo
# operationId: SaveCompanyInfo
export def "user-customer-account-company-info get-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accounting-emails: list<string> # Your company accounting emails (e.g. [myaccountemail@mysupercompany.com])
  address: string # Your address (e.g. 21 jump street)
  city: string # Your address city (e.g. New-York)
  company: string # Your company name (e.g. My super company)
  country_iso_code_alpha3: string # The country iso code alpha 3 (ISO 3166-1_alpha-3) (https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3) (e.g. FRA)
  postal_code: string # Your address postal code (e.g. 13014)
  --vat-number: string # Your company VATNumber. Used for french company. This number is checked with official web service before being saved. (e.g. 1234567890)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/companyInfo")
  let req_body = {"accountingEmails": $accounting_emails, "address": $address, "city": $city, "company": $company, "countryIsoCodeAlpha3": $country_iso_code_alpha3, "postalCode": $postal_code, "vatNumber": $vat_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get credit card information
#
# GET /v2/user/customer/account/creditCardInfo
# operationId: GetCreditCardInfo
export def "user-customer-account-credit-card-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<creditCardInfo: record<cardNumber: string, cardType: string, expirationMonth: int, expirationYear: int>, currentPaymentMethod: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/creditCardInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save user credit card info
#
# PUT /v2/user/customer/account/creditCardInfo
# operationId: SaveCreditCardInfo
export def "user-customer-account-credit-card-info get-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  card_number: string # Card number (e.g. 1234567890091234)
  card_verification_code: string # Card Verification Code (e.g. 123)
  expiration_month: int # Expiration Month (format: int32, e.g. 12)
  expiration_year: int # Expiration Year (format: int32, e.g. 2017)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/creditCardInfo")
  let req_body = {"cardNumber": $card_number, "cardVerificationCode": $card_verification_code, "expirationMonth": $expiration_month, "expirationYear": $expiration_year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Save user personal information
#
# PUT /v2/user/customer/account/personalInfo
# operationId: SavePersonalInfo
export def "user-customer-account-personal-info get-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beez_up_time_zone_id: int # The time zone identifier based on the list of values /v2/user/lov/BeezUPTimeZone (format: int32, e.g. 79)
  first_name: string # Your first name (e.g. Paul)
  last_name: string # Your last name (e.g. Simon)
  phone_number: string # Your phone number (e.g. 5551234)
  --what-i-do: string # Your role in your company (e.g. I'm the Manager on this company)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/personalInfo")
  let req_body = {"beezUPTimeZoneId": $beez_up_time_zone_id, "firstName": $first_name, "lastName": $last_name, "phoneNumber": $phone_number, "whatIDo": $what_i_do} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get profile picture information
#
# GET /v2/user/customer/account/profilePictureInfo
# operationId: GetProfilePictureInfo
export def "user-customer-account-profile-picture-info get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, profilePictureInfo: record<profilePictureSelected: string, profilePictureUrl: string, gravatarProfilePictureUrl: string, initialsProfilePictureUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/profilePictureInfo")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change user picture information
#
# PUT /v2/user/customer/account/profilePictureInfo
# operationId: SaveProfilePictureInfo
export def "user-customer-account-profile-picture-info get-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  profile_picture_selected: string@profile-picture-selected-completer # Your profile picture choice about usage of gravatar picture, initials picture or uploaded picture. (e.g. initials)
  --profile-picture-url: string # Indicate the url of your picture profil (e.g. https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Marlon_Brando_%28cropped%29.jpg/220px-Marlon_Brando_%28cropped%29.jpg)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/profilePictureInfo")
  let req_body = {"profilePictureSelected": $profile_picture_selected, "profilePictureUrl": $profile_picture_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Resend email activation
#
# POST /v2/user/customer/account/resendEmailActivation
# operationId: ResendEmailActivation
export def "user-customer-account-resend-email-activation resend" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/resendEmailActivation")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get billing periods conditions
#
# GET /v2/user/customer/billingPeriods
# operationId: GetBillingPeriods
export def "user-customer-billing-periods get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<billingPeriods: table<billingPeriodInMonth: int, discountPercentage: float>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/billingPeriods")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contract list
#
# GET /v2/user/customer/contracts
# operationId: GetContracts
export def "user-customer-contracts get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<current: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<disable: record, reenable: record>>, links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, next: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<delete: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new contract
#
# POST /v2/user/customer/contracts
# operationId: CreateContract
export def "user-customer-contracts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_period_in_month: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --coupon-discount-code: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --coupon-offer-code: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offer_id: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  store_count: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts")
  let req_body = {"billingPeriodInMonth": $billing_period_in_month, "couponDiscountCode": $coupon_discount_code, "couponOfferCode": $coupon_offer_code, "offerId": $offer_id, "storeCount": $store_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Schedule termination of your current contract at the end of the commitment.
#
# POST /v2/user/customer/contracts/current/disableAutoRenewal
# operationId: TerminateCurrentContract
export def "user-customer-contracts-current-disable-auto-renewal get-terminate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contract-termination-reason: string # The termination reason, if your current contract is scheduled to be terminated. (e.g. I'm crazy, I want to leave your splendid service...)
  contract_termination_reason_type: int # The contract termination reason type identifier, if your current contract is scheduled to be terminated. The value is based on the list of values /user/lov/ContractTerminationReason (format: int32, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts/current/disableAutoRenewal")
  let req_body = {"contractTerminationReason": $contract_termination_reason, "contractTerminationReasonType": $contract_termination_reason_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Reactivate your terminated contract.
#
# POST /v2/user/customer/contracts/current/reenableAutoRenewal
# operationId: ReactivateCurrentContract
export def "user-customer-contracts-current-reenable-auto-renewal get-reactivate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts/current/reenableAutoRenewal")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete your next contract
#
# DELETE /v2/user/customer/contracts/next
# operationId: DeleteNextContract
export def "user-customer-contracts-next delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts/next")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get friend information
#
# GET /v2/user/customer/friends/{userId}
# operationId: GetFriendInfo
export def "user-customer-friends get-get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<company: string, countryIsoCodeAlpha3: string, email: string, firstName: string, lastName: string, profilePictureUrl: string, userId: string, whatIDo: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: (encode-path-segment $user_id)} | format pattern "/v2/user/customer/friends/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all your invoices
#
# GET /v2/user/customer/invoices
# operationId: GetInvoices
export def "user-customer-invoices get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<invoices: table<amount: float, amountToBePaid: float, contractId: string, currencyCode: string, dueDate: string, invoiceDate: string, invoiceNumber: string, invoiceUrl: string, paymentStatus: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/invoices")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all standard offers
#
# GET /v2/user/customer/offers
# operationId: GetStandardOffers
export def "user-customer-offers get-standard" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<functionalities: table<code: string, order: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, offers: table<additionalClickPrice: float, currencyCode: string, fixedPrice: float, functionalities: list, includedClick: int, isMostPopular: bool, isOldOffer: bool, links: record, name: string, offerId: int, position: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/offers")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get offer pricing
#
# POST /v2/user/customer/offers
# operationId: GetOffer
export def "user-customer-offers get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  billing_period_in_month: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --coupon-discount-code: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --coupon-offer-code: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offer_id: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  store_count: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> record<content: record<contractBillingPeriodInfo: record<amountBillingPeriodDiscount: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float>, contractBonusInfo: record<bonuses: list>, contractClickInfo: record<additionalClickPrice: float, clickIncluded: int, initialOfferClickIncluded: int>, contractCommitmentInfo: record<commercialCreatorUserId: string, commercialUserId: string, commitmentCalculatedFinishDate: string, commitmentPeriodInMonth: int, contractType: int, couponOfferCode: string, currentContractId: string, currentContractTerminationDate: string, currentCustomerPaymentMethod: string, fixedAndVariableClickInfo: record, isCustomerWantsToTerminateHisContract: bool, isModelMustBeTransmittedInNewContract: bool, minBillingPeriodInMonths: int, model: string, newContractStartDate: string, offerId: int, offerName: string, paymentDelayInDays: int, paymentMethodAuthorized: string, requestedPaymentMethod: string, trialPeriodFinishDate: string, trialPeriodInMonth: int, variableModelInfo: record>, contractDiscountInfo: record<amountCodePromoDiscount: float, amountCodePromoDiscountPerMonth: float, couponDiscountCode: string, couponDiscountId: int, customerHasActualDiscount: bool, discountDurationInMonth: int, isCouponDiscountLinkedToCouponOffer: bool, percentDiscount: float, promotionalCodeValidity: string>, contractMoneyInfo: record<amountExcludingTaxesAndExcludingCodePromoDiscountIncludingBillingPeriodDiscount: float, amountExcludingTaxesAndExcludingDiscounts: float, amountExcludingTaxesIncludingDiscounts: float, amountExcludingTaxesIncludingDiscountsPerMonth: float, amountIncludingTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountIncludingTaxesIncludingDiscounts: float, amountTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountTaxesIncludingDiscounts: float, currencyCode: string, initialOfferFixedPrice: float, vatPercent: float>, contractStoreInfo: record<additionalStorePrice: float, maxStoreCount: int, minStoreCount: int, ownedStoreCount: int, storeCount: int, storeIncluded: int>, contractTerminationReason: string, contractTerminationReasonType: int, notifyVatExemption: bool, previousFixPeriodInvoiceProrataInfo: record<amountAfterTax: float, amountToBePaid: float, computedProrataToBeDeducted: float, contractId: string, fixedPeriodEndDate: string, fixedPeriodStartDate: string, invoiceNumber: string>>, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<createContract: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/offers")
  let req_body = {"billingPeriodInMonth": $billing_period_in_month, "couponDiscountCode": $coupon_discount_code, "couponOfferCode": $coupon_offer_code, "offerId": $offer_id, "storeCount": $store_count} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Log out the current user from go2
#
# POST /v2/user/customer/security/logout
# operationId: Logout
export def "user-customer-security-logout create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/security/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store list
#
# GET /v2/user/customer/stores
# operationId: GetStores
export def "user-customer-stores list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<createStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, stores: table<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list, shareCount: int, status: string, storeId: string, url: string, userRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/stores")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new store
#
# POST /v2/user/customer/stores
# operationId: CreateStore
export def "user-customer-stores create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  country_iso_code_alpha3: string # The country iso code alpha 3 based on the list of values /user/lov/StoreCountry (e.g. DEU)
  --id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list<string> # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/stores")
  let req_body = {"countryIsoCodeAlpha3": $country_iso_code_alpha3, "id": $id, "name": $name, "sectors": $sectors, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a store
#
# DELETE /v2/user/customer/stores/{storeId}
# operationId: DeleteStore
export def "user-customer-stores delete" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store's information
#
# GET /v2/user/customer/stores/{storeId}
# operationId: GetStore
export def "user-customer-stores get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record<deleteStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, shares: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, updateStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list<string>, shareCount: int, status: string, storeId: string, url: string, userRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update some store's information.
#
# PATCH /v2/user/customer/stores/{storeId}
# operationId: UpdateStore
export def "user-customer-stores update" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list<string> # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}"))
  let req_body = {"name": $name, "sectors": $sectors, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get store's alerts
#
# GET /v2/user/customer/stores/{storeId}/alerts
# operationId: GetStoreAlerts
export def "user-customer-stores-alerts get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<alerts: table<alertId: int, alertName: string, enabled: bool, links: record, properties: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}/alerts"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save store alerts
#
# POST /v2/user/customer/stores/{storeId}/alerts
# operationId: SaveStoreAlerts
export def "user-customer-stores-alerts create-save" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}/alerts"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get store's rights
#
# GET /v2/user/customer/stores/{storeId}/rights
# operationId: GetRights
export def "user-customer-stores-rights get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<functionalityCode: string, maxValueInterger: int, unlimited: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}/rights"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shares related to this store
#
# GET /v2/user/customer/stores/{storeId}/shares
# operationId: GetStoreShares
export def "user-customer-stores-shares get" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, shares: table<links: record, userId: string, userRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}/shares"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Share a store to another user
#
# POST /v2/user/customer/stores/{storeId}/shares
# operationId: ShareStore
export def "user-customer-stores-shares create" [
  store_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id)} | format pattern "/v2/user/customer/stores/{store_id}/shares"))
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Delete a share of a store to another user
#
# DELETE /v2/user/customer/stores/{storeId}/shares/{userId}
# operationId: DeleteStoreShare
export def "user-customer-stores-shares delete" [
  store_id: string
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({store_id: (encode-path-segment $store_id), user_id: (encode-path-segment $user_id)} | format pattern "/v2/user/customer/stores/{store_id}/shares/{user_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Zendesk token
#
# GET /v2/user/customer/zendeskToken
# operationId: ZendeskToken
export def "user-customer-zendesk-token get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/zendeskToken")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all your current channel catalogs configured to use legacy tracking format
#
# GET /v2/user/legacyTracking/channelCatalogs/
# operationId: GetLegacyTrackingChannelCatalogs
export def "user-legacy-tracking-channel-catalogs list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<channelCatalogs: record, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/legacyTracking/channelCatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the channel catalog configured to use legacy tracking format information
#
# GET /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}
# operationId: GetLegacyTrackingChannelCatalog
export def "user-legacy-tracking-channel-catalogs get" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<migrate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/legacyTracking/channelCatalogs/{channel_catalog_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Migrate a channel catalog to current tracking format
#
# POST /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}/migrate
# operationId: MigrateLegacyTrackingChannelCatalog
export def "user-legacy-tracking-channel-catalogs-migrate create" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/legacyTracking/channelCatalogs/{channel_catalog_id}/migrate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all list names
#
# GET /v2/user/lov/
# operationId: GetUserLovIndex
export def "user-lov get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/lov/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of values related to this list name
#
# GET /v2/user/lov/{listName}
# operationId: GetUserListOfValues
export def "user-lov get-list-of-values" [
  list_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-language: list<string> # Indicates that the client accepts the following languages.
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({list_name: (encode-path-segment $list_name)} | format pattern "/v2/user/lov/{list_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language, "If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your marketplace channel catalog list
#
# GET /v2/user/marketplaces/channelcatalogs/
# operationId: GetMarketplaceChannelCatalogs
export def "user-marketplaces-channelcatalogs get-channel-catalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceChannelCatalogs: table<apiSettingsStatus: string, beezUPChannelCatalogId: string, beezUPChannelId: string, beezUPMarketplaceName: any, beezUPStoreId: string, beezUPStoreName: string, enabled: bool, links: record, lovLinks: record, marketplaceAccountId: int, marketplaceBusinessCode: string, marketplaceIsoCountryCodeAlpha2: string, marketplaceMarketPlaceId: string, marketplaceMerchantIdentifiers: record, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/channelcatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the publication history for an account, sorted by descending start date
#
# GET /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/history
# operationId: GetPublications
export def "user-marketplaces-channelcatalogs-publications-history get" [
  marketplace_technical_code: string
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channel-catalog-id: string # Channel Catalog Id by which to filter (optional) (format: guid)
  --count: int # Amount of entries to fetch (optional, default set to 10) (format: int32, default: 10)
  --publication-types: list<string> # Publication types by which to filter (optional)
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, publications: table<feeds: list, publicationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelCatalogId" $channel_catalog_id "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "publicationTypes" $publication_types "csv")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id)} | format pattern "/v2/user/marketplaces/channelcatalogs/publications/{marketplace_technical_code}/{account_id}/history") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [PREVIEW] Launch a publication of the catalog to the marketplace
#
# POST /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/publish
# operationId: PublishCatalogToMarketplace
export def "user-marketplaces-channelcatalogs-publications-publish publish-catalog" [
  marketplace_technical_code: string
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feed_type: string@feed-type-completer # The Feed Type (e.g. Offers)
  publication_strategy_kind: string@publication-strategy-kind-completer # Define the publication strategy kind, for that you have 2 choices * Delta - This is the recommanded publication strategy kind, this strategy will push to the marketplace only the difference between your catalog and the previous published feeds done by BeezUP. * Full - If you want to force the publication of all your catalog feeds to the marketplace. !WARNING! Depending to the marketplace this operation will purge the existing offers on the marketplace that are not in the catalog or unknown from the publication feed referential. (default: Delta)
  --with-unpublish: oneof<nothing, bool> # In full publication strategy kind, for some marktetplace, you can ask to unpublish or not your existing feeds on the markeptlace absent from your exported catalog.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id)} | format pattern "/v2/user/marketplaces/channelcatalogs/publications/{marketplace_technical_code}/{account_id}/publish"))
  let req_body = {"feedType": $feed_type, "publicationStrategyKind": $publication_strategy_kind, "withUnpublish": $with_unpublish} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get the marketplace properties for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/properties
# operationId: GetChannelCatalogMarketplaceProperties
export def "user-marketplaces-channelcatalogs-properties get-channel-catalog" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirection-page-url: string # format: uri
  --accept-language: list<string> # Indicates that the client accepts the following languages.
]: nothing -> record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<externalConfigurationPage: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, settings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, propertyGroups: table<name: string, position: int, properties: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirectionPageUrl" $redirection_page_url "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/marketplaces/channelcatalogs/{channel_catalog_id}/properties") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Language": $accept_language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the marketplace settings for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# operationId: GetChannelCatalogMarketplaceSettings
export def "user-marketplaces-channelcatalogs-settings get-channel-catalog" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, settings: table<discriminatorType: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/marketplaces/channelcatalogs/{channel_catalog_id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save new marketplace settings for a channel catalog
#
# POST /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# operationId: SetChannelCatalogMarketplaceSettings
# --settings item shape: {discriminatorType: "channelCatalogMarketplaceStringSetting"|"channelCatalogMarketplaceIntegerSetting"|"channelCatalogMarketplaceBooleanSetting"|"channelCatalogMarketplaceNumberSetting", name: string}
export def "user-marketplaces-channelcatalogs-settings update-channel-catalog" [
  channel_catalog_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  settings: list # e.g. [{name: Country, values: [FR]}, {name: Currency, values: [EUR]}, {name: ListingDuration, values: [GTC]}, {name: PaymentMethods, values: [CCAccepted]}, {name: PayPalEmailAddress, values: [pascal@ixeoline.com]}, {name: PostalCode, values: [69630]}, {name: RefundOption, values: [MoneyBackOrExchange]}, {name: ReturnsAcceptedOption, values: [ReturnsAccepted]}, {name: ReturnsWithinOption, values: [Days_10]}, {name: ShippingCostPaidByOption, values: [Buyer]}, {name: ShippingService, values: [FR_ColiposteColissimo]}] — item shape: {discriminatorType: "channelCatalogMarketplaceStringSetting"|"channelCatalogMarketplaceIntegerSetting"|"channelCatalogMarketplaceBooleanSetting"|"channelCatalogMarketplaceNumberSetting", name: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({channel_catalog_id: (encode-path-segment $channel_catalog_id)} | format pattern "/v2/user/marketplaces/channelcatalogs/{channel_catalog_id}/settings"))
  let req_body = {"settings": $settings} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Get all actions you can do on the order API
#
# GET /v2/user/marketplaces/orders/
# DEPRECATED
# operationId: GetOrderIndex
@deprecated
export def "user-marketplaces-orders get-index" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<autoTransitions: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, lightOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, orders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<orderChangeBusinessOperationType: record<href: string, method: string>, orderProperty: record<href: string, method: string>, orderPropertyPosted: record<href: string, method: string>, orderState: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of configured automatic Order status transitions
#
# GET /v2/user/marketplaces/orders/automaticTransitions
# operationId: GetAutomaticTransitions
export def "user-marketplaces-orders-automatic-transitions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<automaticTransitionInfos: table<accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int, beezUPOrderStatus: string, businessOperationType: string, links: record, marketplaceBusinessCode: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/automaticTransitions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure new or existing automatic Order status transition
#
# POST /v2/user/marketplaces/orders/automaticTransitions
# operationId: ConfigureAutomaticTransitions
# --automaticTransitions item shape: {accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int}
export def "user-marketplaces-orders-automatic-transitions create-configure" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  automatic_transitions: list # item shape: {accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/automaticTransitions")
  let req_body = {"automaticTransitions": $automatic_transitions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Send a batch of operations to change your marketplace Order information: accept, ship, etc. (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/changeOrders/{changeOrderType}
# DEPRECATED
# operationId: ChangeOrderList
# --changeOrders item shape: {changeOrderRequest?: record, order: any}
@deprecated
export def "user-marketplaces-orders-batches-change-orders list" [
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  change_orders: list # The change order operations — item shape: {changeOrderRequest?: record, order: any}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({change_order_type: (encode-path-segment $change_order_type)} | format pattern "/v2/user/marketplaces/orders/batches/changeOrders/{change_order_type}") $qp)
  let req_body = {"changeOrders": $change_orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/clearMerchantOrderInfos
# DEPRECATED
# operationId: ClearMerchantOrderInfoList
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
@deprecated
export def "user-marketplaces-orders-batches-clear-merchant-order-infos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 5678, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 9876, beezUPOrderId: 0, marketplaceTechnicalCode: Ebay}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/batches/clearMerchantOrderInfos")
  let req_body = {"orders": $orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Send a batch of operations to set an Order's merchant information (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/setMerchantOrderInfos
# DEPRECATED
# operationId: SetMerchantOrderInfoList
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
@deprecated
export def "user-marketplaces-orders-batches-set-merchant-order-infos list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/batches/setMerchantOrderInfos")
  let req_body = {"order_MerchantECommerceSoftwareName": $order_merchant_e_commerce_software_name, "order_MerchantECommerceSoftwareVersion": $order_merchant_e_commerce_software_version, "orders": $orders} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get a paginated list of Order report exportations
#
# GET /v2/user/marketplaces/orders/exportations
# operationId: GetOrderExportations
export def "user-marketplaces-orders-exportations get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # The page number you want to get (format: int32, e.g. 1)
  --page-size: int # The entry count you want to get (format: int32, e.g. 25)
  --store-id: string # The store identifier to regroup the order exportations (format: guid)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<exportations: table<abortionUtcDate: string, beginUtcDate: string, blobNameUri: string, endUtcDate: string, enqueuedUtcDate: string, errorMessage: string, executionUUID: string, expirationUtcDate: string, failureUtcDate: string, ipAddress: string, jsonCriteria: string, lastUpdateUtcDate: string, orderCount: int, processingStatus: string, remainingOrderCount: int, resumedUtcDate: string, sourceType: string, sourceUserId: string, sourceUserName: string, suspendedUtcDate: string, timeoutDuration: string, warningMessage: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/exportations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a new Order report exportation to be generated
#
# POST /v2/user/marketplaces/orders/exportations
# operationId: ExportOrders
# --orderListRequestWithoutPagination shape: {accountIds?: list<int>, beezUPOrderStatuses?: list<string>, beginPeriodUtcDate: string, dateSearchType?: "Modification"|"Purchase"|"MarketPlaceModification", endPeriodUtcDate: string, invoiceAvailabilityType?: string, marketplaceBusinessCodes?: list<string>, marketplaceOrderIds?: list<string>, marketplaceTechnicalCodes?: list<string>, orderMerchantInfoSynchronizationStatus?: string, order_Buyer_Name?: string, order_MerchantOrderIds?: list<string>, storeIds?: list<string>}
export def "user-marketplaces-orders-exportations export" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # The type of the file to export (default: csv, e.g. csv)
  order_list_request_without_pagination: record # shape: {accountIds?: list<int>, beezUPOrderStatuses?: list<string>, beginPeriodUtcDate: string, dateSearchType?: "Modification"|"Purchase"|"MarketPlaceModification", endPeriodUtcDate: string, invoiceAvailabilityType?: string, marketplaceBusinessCodes?: list<string>, marketplaceOrderIds?: list<string>, marketplaceTechnicalCodes?: list<string>, orderMerchantInfoSynchronizationStatus?: string, order_Buyer_Name?: string, order_MerchantOrderIds?: list<string>, storeIds?: list<string>}
  store_id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/exportations")
  let req_body = {"format": $format, "orderListRequestWithoutPagination": $order_list_request_without_pagination, "storeId": $store_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Send harvest request to all your marketplaces
#
# POST /v2/user/marketplaces/orders/harvest
# DEPRECATED
# operationId: HarvestAll
@deprecated
export def "user-marketplaces-orders-harvest list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/harvest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate an Order Invoice batch
#
# POST /v2/user/marketplaces/orders/invoices/generate
# operationId: GenerateBatchOrderInvoice
export def "user-marketplaces-orders-invoices-generate generate-batch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --body: record
]: any -> table<accountId: int, beezUPOrderUUID: string, invoiceLocation: string, invoiceSequenceNumber: int, marketplaceTechnicalCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/generate" $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Returns the PDF version of the invoice
#
# POST /v2/user/marketplaces/orders/invoices/getPdfInvoice
# operationId: GetOrderInvoicePdf
export def "user-marketplaces-orders-invoices-get-pdf-invoice get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  order_invoice_uri: string # order invoice url (e.g. http://www.mydomain.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/getPdfInvoice")
  let req_body = {"orderInvoiceUri": $order_invoice_uri} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Order Invoice design settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/design
# operationId: GetOrderInvoiceDesignSettings
export def "user-marketplaces-orders-invoices-settings-design get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<footerContentHtml: string, headerContentHtml: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/design")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Order Invoice design settings
#
# PUT /v2/user/marketplaces/orders/invoices/settings/design
# operationId: SaveOrderInvoiceDesignSettings
export def "user-marketplaces-orders-invoices-settings-design update-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --footer-content-html: string # Footer Content HTML
  --header-content-html: string # Header Content HTML
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/design")
  let req_body = {"footerContentHtml": $footer_content_html, "headerContentHtml": $header_content_html} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# View a preview an Order Invoice using custom design settings
#
# POST /v2/user/marketplaces/orders/invoices/settings/design/preview
# operationId: GetOrderInvoiceDesignSettingsPreview
export def "user-marketplaces-orders-invoices-settings-design-preview get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --footer-content-html: string # Footer Content HTML
  --header-content-html: string # Header Content HTML
]: any -> record<invoiceHtmlContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/design/preview")
  let req_body = {"footerContentHtml": $footer_content_html, "headerContentHtml": $header_content_html} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Get Order Invoice general settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/general
# operationId: GetOrderInvoiceGeneralSettings
export def "user-marketplaces-orders-invoices-settings-general get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cultureName: string, invoicePrefix: string, invoiceStartingSequenceNumber: int, productVATPercent: float, shippingVATPercent: float, lastInvoiceSequenceNumber: int> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/general")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save Order Invoice general settings
#
# PUT /v2/user/marketplaces/orders/invoices/settings/general
# operationId: SaveOrderInvoiceGeneralSettings
export def "user-marketplaces-orders-invoices-settings-general update-save" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  culture_name: string # If the error is translated, the culture name will be indicated (e.g. en)
  invoice_prefix: string # Invoice Prefix. Can contain 1 to 50 characters, with alphanumeric characters in lowercase uppercase and #, _, - (e.g. TOTO)
  invoice_starting_sequence_number: int # Invoice Sequence Number (e.g. 879)
  product_vat_percent: float # Product VAT in percent (e.g. 4.0)
  shipping_vat_percent: float # Shipping cost VAT in percent (e.g. 8.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/general")
  let req_body = {"cultureName": $culture_name, "invoicePrefix": $invoice_prefix, "invoiceStartingSequenceNumber": $invoice_starting_sequence_number, "productVATPercent": $product_vat_percent, "shippingVATPercent": $shipping_vat_percent} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Generate an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/generate
# operationId: GenerateOrderInvoice
export def "user-marketplaces-orders-invoices-generate generate" [
  marketplace_technical_code: string
  account_id: string
  beez_up_order_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --invoice-sequence-number: int # Invoice Sequence Number (e.g. 879)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_uuid: (encode-path-segment $beez_up_order_uuid)} | format pattern "/v2/user/marketplaces/orders/invoices/{marketplace_technical_code}/{account_id}/{beez_up_order_uuid}/generate") $qp)
  let req_body = {"invoiceSequenceNumber": $invoice_sequence_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# View a preview an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/preview
# operationId: GetOrderInvoicePreview
export def "user-marketplaces-orders-invoices-preview get" [
  marketplace_technical_code: string
  account_id: string
  beez_up_order_uuid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --invoice-sequence-number: int # Invoice Sequence Number (e.g. 879)
]: any -> record<invoiceHtmlContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_uuid: (encode-path-segment $beez_up_order_uuid)} | format pattern "/v2/user/marketplaces/orders/invoices/{marketplace_technical_code}/{account_id}/{beez_up_order_uuid}/preview"))
  let req_body = {"invoiceSequenceNumber": $invoice_sequence_number} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /v2/user/marketplaces/orders/list/full
# DEPRECATED
# operationId: GetOrderListFull
@deprecated
export def "user-marketplaces-orders-list-full get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept-encoding: list<string> # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/list/full")
  let req_body = {"accountIds": $account_ids, "beezUPOrderStatuses": $beez_up_order_statuses, "beginPeriodUtcDate": $begin_period_utc_date, "dateSearchType": $date_search_type, "endPeriodUtcDate": $end_period_utc_date, "invoiceAvailabilityType": $invoice_availability_type, "marketplaceBusinessCodes": $marketplace_business_codes, "marketplaceOrderIds": $marketplace_order_ids, "marketplaceTechnicalCodes": $marketplace_technical_codes, "orderMerchantInfoSynchronizationStatus": $order_merchant_info_synchronization_status, "order_Buyer_Name": $order_buyer_name, "order_MerchantOrderIds": $order_merchant_order_ids, "storeIds": $store_ids, "pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Accept-Encoding": $accept_encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Get a paginated list of all Orders without details
#
# POST /v2/user/marketplaces/orders/list/light
# DEPRECATED
# operationId: GetOrderListLight
@deprecated
export def "user-marketplaces-orders-list-light get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: list<int> # Account Id list (e.g. [12345])
  --beez-up-order-statuses: list<string> # e.g. [InProgress]
  begin_period_utc_date: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period. (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --date-search-type: string@date-search-type-completer # Indicates on which date you want to make the filter (default: Modification)
  end_period_utc_date: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date. (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoice-availability-type: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplace-business-codes: list<string> # e.g. [PRICEMINISTER]
  --marketplace-order-ids: list<string> # e.g. [AmazonOrderId1234]
  --marketplace-technical-codes: list<string> # e.g. [PriceMinister]
  --order-merchant-info-synchronization-status: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-buyer-name: string # Buyer full name (e.g. Monroe)
  --order-merchant-order-ids: list<string> # Merchant order id list (e.g. [MyOrderId1234])
  --store-ids: list<string> # Store Id list
  page_number: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  page_size: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/list/light")
  let req_body = {"accountIds": $account_ids, "beezUPOrderStatuses": $beez_up_order_statuses, "beginPeriodUtcDate": $begin_period_utc_date, "dateSearchType": $date_search_type, "endPeriodUtcDate": $end_period_utc_date, "invoiceAvailabilityType": $invoice_availability_type, "marketplaceBusinessCodes": $marketplace_business_codes, "marketplaceOrderIds": $marketplace_order_ids, "marketplaceTechnicalCodes": $marketplace_technical_codes, "orderMerchantInfoSynchronizationStatus": $order_merchant_info_synchronization_status, "order_Buyer_Name": $order_buyer_name, "order_MerchantOrderIds": $order_merchant_order_ids, "storeIds": $store_ids, "pageNumber": $page_number, "pageSize": $page_size} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /v2/user/marketplaces/orders/status
# DEPRECATED
# operationId: GetMarketplaceAccountsSynchronization
@deprecated
export def "user-marketplaces-orders-status get-accounts-synchronization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --store-id: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $store_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/status" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the subscription list
#
# GET /v2/user/marketplaces/orders/subscriptions/
# operationId: GetSubscriptionList
export def "user-marketplaces-orders-subscriptions get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record, deactivate: record, delete: record, reporting: record, retry: record>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/subscriptions/")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a subscription to the orders
#
# DELETE /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: DeleteSubscription
export def "user-marketplaces-orders-subscriptions delete" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subscription to the orders
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: GetSubscription
export def "user-marketplaces-orders-subscriptions get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<consumerHealthStatus: string, consumerLastRequestSentUri: string, consumerUnvailableSinceUtcDate: string, id: string, lastErrorMessage: record<errors: list<record>>, lastOrderPushedModificationUtcDate: string, lastRetryUtcDate: string, lastSuccessfulOrderPushedUtcDate: string, maxRetryCount: int, merchantApplicationName: string, merchantApplicationVersion: string, merchantEmailAlert: string, name: string, nextScheduledRetryUtcDate: string, recoverBeginPeriodOrderLastModificationUtcDate: string, recoverEndPeriodOrderLastModificationUtcDate: string, retryCount: int, status: string, targetUrl: string, links: record<activate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, deactivate: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, delete: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, reporting: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>, retry: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, rel: string, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: CreateSubscription
export def "user-marketplaces-orders-subscriptions create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  merchant_application_name: string # The name of your application (e.g. MyApp)
  merchant_application_version: string # The version of your application (default: 1.0, e.g. 1.0)
  --merchant-email-alert: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
  name: string # The subscription name you want to use (e.g. MySubscriptionName)
  target_url: string # The URL https://en.wikipedia.org/wiki/URL (https://en.wikipedia.org/wiki/URL) (e.g. http://www.mydomain.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}"))
  let req_body = {"merchantApplicationName": $merchant_application_name, "merchantApplicationVersion": $merchant_application_version, "merchantEmailAlert": $merchant_email_alert, "name": $name, "targetUrl": $target_url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Activate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/activate
# operationId: ActivateSubscription
export def "user-marketplaces-orders-subscriptions-activate create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recover-begin-period-order-last-modification-utc-date: string # If set, the date must be in the past the subscription will recover existing orders using the begin period order last modification date. If not set then you will receive new/updated orders in real-time. (format: date-time)
  --recover-end-period-order-last-modification-utc-date: string # If end period set, first the date must be in the past, the subscription will recover existing orders using the begin and the end period order last modification date. If end period is not set and the begin period is set, then you will recover existing orders from the past using the begin period last modification date and after than you will continue to receive new/updated orders in real-time. If begin/end period are not set then you will receive new/updated orders in real-time. REMARK: The begin period is required if the end period is fulfilled. REMARK: If the end period is order last modification date is indicated then once we have push all orders to your target url the subscription will be desactivated. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}/activate"))
  let req_body = {"recoverBeginPeriodOrderLastModificationUtcDate": $recover_begin_period_order_last_modification_utc_date, "recoverEndPeriodOrderLastModificationUtcDate": $recover_end_period_order_last_modification_utc_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# Deactivate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/deactivate
# operationId: DeactivateSubscription
export def "user-marketplaces-orders-subscriptions-deactivate create" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}/deactivate"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the push reporting related to this subscription
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}/reporting
# operationId: GetSubscriptionPushReporting
export def "user-marketplaces-orders-subscriptions-reporting get-push" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --page-number: int # format: PageNumber
  --page-size: int # format: PageSize
]: nothing -> table<duration: string, errorMessage: record<errors: list>, eventId: string, httpStatus: int, lastOrderModificationUtcDate: string, maxRetryCount: int, nextScheduledRetryUtcDate: string, orderCount: int, requestUri: string, responseUri: string, retryCount: int, subscriptionId: string, succeed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $page_number "scalar") (serialize-qp "pageSize" $page_size "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}/reporting") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force retry push orders immediatly
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/retry
# operationId: RetryPushOrders
export def "user-marketplaces-orders-subscriptions-retry push" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/v2/user/marketplaces/orders/subscriptions/{id}/retry"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] DEPRECATED - Get full Order and Order Item(s) properties
#
# GET /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# DEPRECATED
# operationId: GetOrder
@deprecated
export def "user-marketplaces-orders get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] DEPRECATED - Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# DEPRECATED
# operationId: HeadOrder
@deprecated
export def "user-marketplaces-orders head-head" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Clear an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# DEPRECATED
# operationId: ClearMerchantOrderInfo
@deprecated
export def "user-marketplaces-orders-clear-merchant-order-info get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/clearMerchantOrderInfo"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Send harvest request for a single Order
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest
# DEPRECATED
# operationId: HarvestOrder
@deprecated
export def "user-marketplaces-orders-harvest create" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/harvest"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Get an Order's harvest and change history
#
# GET /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history
# DEPRECATED
# operationId: GetOrderHistory
@deprecated
export def "user-marketplaces-orders-history get" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --if-none-match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/history"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-None-Match": $if_none_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Set an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# DEPRECATED
# operationId: SetMerchantOrderInfo
@deprecated
export def "user-marketplaces-orders-set-merchant-order-info update" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  order_merchant_e_commerce_software_name: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_merchant_e_commerce_software_version: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_merchant_order_id: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/setMerchantOrderInfo"))
  let req_body = {"order_MerchantECommerceSoftwareName": $order_merchant_e_commerce_software_name, "order_MerchantECommerceSoftwareVersion": $order_merchant_e_commerce_software_version, "order_MerchantOrderId": $order_merchant_order_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}

# [DEPRECATED] Change your marketplace Order Information (accept, ship, etc.)
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# DEPRECATED
# operationId: ChangeOrder
@deprecated
export def "user-marketplaces-orders create-change" [
  marketplace_technical_code: string
  account_id: int
  beez_up_order_id: string
  change_order_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --user-name: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --test-mode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --if-match: string # ETag value to identify the last known version of requested resource.\ To ensure that you are making a change on the lastest version of the resource.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $user_name "scalar") (serialize-qp "testMode" $test_mode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({marketplace_technical_code: (encode-path-segment $marketplace_technical_code), account_id: (encode-path-segment $account_id), beez_up_order_id: (encode-path-segment $beez_up_order_id), change_order_type: (encode-path-segment $change_order_type)} | format pattern "/v2/user/marketplaces/orders/{marketplace_technical_code}/{account_id}/{beez_up_order_id}/{change_order_type}") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"If-Match": $if_match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $req_body
}
