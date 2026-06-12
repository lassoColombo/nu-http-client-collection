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
def dateSearchType-completer [] { ["MarketPlaceModification" "Modification" "Purchase"] }
def productState-completer [] { ["All" "Disabled" "Enabled"] }
def reportType-completer [] { ["ByCategory" "ByChannel" "ByDay" "ByProduct"] }
def optimisationActionName-completer [] { ["disable" "reenable"] }
def format-completer [] { ["csv" "xlsx"] }
def costType-completer [] { ["CPA_ByCategory" "CPA_Global" "CPC_ByCategory" "CPC_Global" "Fixed_Global"] }
def profilePictureSelected-completer [] { ["gravatar" "initials" "uploaded"] }
def feedType-completer [] { ["Images" "Inventory" "Offers" "Pricing" "Products" "Relationships" "Unpublish"] }
def publicationStrategyKind-completer [] { ["Delta" "Full"] }
def format-completer-1 [] { ["csv"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "orders-batches-change-orders ChangeOrderListV3" } } | get name | first)
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

# Send a batch of operations to change your marketplace Order information: accept, ship, etc.  (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders
# operationId: ChangeOrderListV3
# --changeOrders item shape: {changeOrderRequest?: record, order: any}
export def "orders-batches-change-orders ChangeOrderListV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  changeOrders: list # The change order operations — item shape: {changeOrderRequest?: record, order: any}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/changeOrders" $qp)
  let body = {changeOrders: $changeOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a batch of operations to change your marketplace Order information: accept, ship, etc.  (max 100 items per call)
#
# POST /orders/v3/batches/changeOrders/{changeOrderType}
# operationId: ChangeOrderListV2
# --changeOrders item shape: {changeOrderRequest?: record, order: record}
export def "orders-batches-change-orders ChangeOrderListV2" [
  changeOrderType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  changeOrders: list # The change order operations — item shape: {changeOrderRequest?: record, order: record}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/v3/batches/changeOrders/($changeOrderType)" $qp)
  let body = {changeOrders: $changeOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /orders/v3/batches/clearMerchantOrderInfos
# operationId: ClearMerchantOrderInfoListV3
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
export def "orders-batches-clear-merchant-order-infos ClearMerchantOrderInfoListV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 5678, beezUPOrderId: 0, marketplaceTechnicalCode: Amazon}, {accountId: 9876, beezUPOrderId: 0, marketplaceTechnicalCode: Ebay}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/clearMerchantOrderInfos" $qp)
  let body = {orders: $orders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send a batch of operations to set an Order's merchant information  (max 100 items per call)
#
# POST /orders/v3/batches/setMerchantOrderInfos
# operationId: SetMerchantOrderInfoListV3
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
export def "orders-batches-set-merchant-order-infos SetMerchantOrderInfoListV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_MerchantECommerceSoftwareName: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_MerchantECommerceSoftwareVersion: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/batches/setMerchantOrderInfos" $qp)
  let body = {order_MerchantECommerceSoftwareName: $order_MerchantECommerceSoftwareName, order_MerchantECommerceSoftwareVersion: $order_MerchantECommerceSoftwareVersion, orders: $orders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Send harvest request to all your marketplaces
#
# POST /orders/v3/harvest
# operationId: HarvestAllV3
export def "orders-harvest HarvestAllV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The StoreId to filter by (format: StoreId, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/harvest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /orders/v3/list/full
# operationId: GetOrderListFullV3
export def "orders-list-full GetOrderListFullV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --accountIds: list # Account Id list (e.g. [12345])
  --beezUPOrderStatuses: list # e.g. [InProgress]
  beginPeriodUtcDate: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period.  (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --dateSearchType: string@dateSearchType-completer # Indicates on which date you want to make the filter (default: Modification)
  endPeriodUtcDate: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date.  (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoiceAvailabilityType: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplaceBusinessCodes: list # e.g. [PRICEMINISTER]
  --marketplaceOrderIds: list # e.g. [AmazonOrderId1234]
  --marketplaceTechnicalCodes: list # e.g. [PriceMinister]
  --orderMerchantInfoSynchronizationStatus: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-Buyer-Name: string # Buyer full name (e.g. Monroe)
  --order-MerchantOrderIds: list # Merchant order id list (e.g. [MyOrderId1234])
  --storeIds: list # Store Id list
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<links: record, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/v3/list/full")
  let body = {accountIds: $accountIds, beezUPOrderStatuses: $beezUPOrderStatuses, beginPeriodUtcDate: $beginPeriodUtcDate, dateSearchType: $dateSearchType, endPeriodUtcDate: $endPeriodUtcDate, invoiceAvailabilityType: $invoiceAvailabilityType, marketplaceBusinessCodes: $marketplaceBusinessCodes, marketplaceOrderIds: $marketplaceOrderIds, marketplaceTechnicalCodes: $marketplaceTechnicalCodes, orderMerchantInfoSynchronizationStatus: $orderMerchantInfoSynchronizationStatus, order_Buyer_Name: $order_Buyer_Name, order_MerchantOrderIds: $order_MerchantOrderIds, storeIds: $storeIds, pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a paginated list of all Orders without details
#
# POST /orders/v3/list/light
# operationId: GetOrderListLightV3
export def "orders-list-light GetOrderListLightV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountIds: list # Account Id list (e.g. [12345])
  --beezUPOrderStatuses: list # e.g. [InProgress]
  beginPeriodUtcDate: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period.  (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --dateSearchType: string@dateSearchType-completer # Indicates on which date you want to make the filter (default: Modification)
  endPeriodUtcDate: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date.  (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoiceAvailabilityType: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplaceBusinessCodes: list # e.g. [PRICEMINISTER]
  --marketplaceOrderIds: list # e.g. [AmazonOrderId1234]
  --marketplaceTechnicalCodes: list # e.g. [PriceMinister]
  --orderMerchantInfoSynchronizationStatus: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-Buyer-Name: string # Buyer full name (e.g. Monroe)
  --order-MerchantOrderIds: list # Merchant order id list (e.g. [MyOrderId1234])
  --storeIds: list # Store Id list
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/orders/v3/list/light")
  let body = {accountIds: $accountIds, beezUPOrderStatuses: $beezUPOrderStatuses, beginPeriodUtcDate: $beginPeriodUtcDate, dateSearchType: $dateSearchType, endPeriodUtcDate: $endPeriodUtcDate, invoiceAvailabilityType: $invoiceAvailabilityType, marketplaceBusinessCodes: $marketplaceBusinessCodes, marketplaceOrderIds: $marketplaceOrderIds, marketplaceTechnicalCodes: $marketplaceTechnicalCodes, orderMerchantInfoSynchronizationStatus: $orderMerchantInfoSynchronizationStatus, order_Buyer_Name: $order_Buyer_Name, order_MerchantOrderIds: $order_MerchantOrderIds, storeIds: $storeIds, pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the list of MarketplaceBusinessCode ready for Order Management
#
# GET /orders/v3/lov/orderManagementReadyMarketplaceBusinessCode
# operationId: GetOrderManagementReadyMarketplaceBusinessCode
export def "orders-lov-order-management-ready-marketplace-business-code GetOrderManagementReadyMarketplaceBusinessCode" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeIds: list # StoredIds to filter
  --Accept-Language: list # Indicates that the client accepts the following languages.
]: nothing -> table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeIds" $storeIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/lov/orderManagementReadyMarketplaceBusinessCode" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /orders/v3/status
# operationId: GetMarketplaceAccountsSynchronizationV3
export def "orders-status GetMarketplaceAccountsSynchronizationV3" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeIds: list # StoredIds to filter
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeIds" $storeIds "csv")] | flatten | str join "&"
  let full_url = (build-url $base "/orders/v3/status" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send harvest request for an Account
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/harvest
# operationId: HarvestAccount
export def "orders-harvest HarvestAccount" [
  marketplaceTechnicalCode: string
  accountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --marketplaceOrderId: string
  --beezUPOrderId: string
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "marketplaceOrderId" $marketplaceOrderId "scalar") (serialize-qp "beezUPOrderId" $beezUPOrderId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/harvest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get full Order and Order Item(s) properties
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# operationId: GetOrderV3
export def "orders GetOrderV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# operationId: HeadOrderV3
export def "orders HeadOrderV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# operationId: ClearMerchantOrderInfoV3
export def "orders-clear-merchant-order-info ClearMerchantOrderInfoV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/clearMerchantOrderInfo" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Send harvest request for a single Order
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/harvest
# operationId: HarvestOrderV3
export def "orders-harvest HarvestOrderV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
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
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/harvest")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an Order's harvest and change history
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history
# operationId: GetOrderHistoryV3
export def "orders-history GetOrderHistoryV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
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
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/history")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the order change reporting
#
# GET /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/history/{orderChangeExecutionUUID}
# operationId: GetOrderChangeReportingV3
export def "orders-history GetOrderChangeReportingV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  orderChangeExecutionUUID: string
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
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/history/($orderChangeExecutionUUID)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set an Order's merchant information
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# operationId: SetMerchantOrderInfoV3
export def "orders-set-merchant-order-info SetMerchantOrderInfoV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  order_MerchantECommerceSoftwareName: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_MerchantECommerceSoftwareVersion: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_MerchantOrderId: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/setMerchantOrderInfo" $qp)
  let body = {order_MerchantECommerceSoftwareName: $order_MerchantECommerceSoftwareName, order_MerchantECommerceSoftwareVersion: $order_MerchantECommerceSoftwareVersion, order_MerchantOrderId: $order_MerchantOrderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change your marketplace Order Information (accept, ship, etc.)
#
# POST /orders/v3/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# operationId: ChangeOrderV3
export def "orders ChangeOrderV3" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  changeOrderType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/orders/v3/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/($changeOrderType)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get public channel index
#
# GET /v2/public/channels/
# operationId: GetChannelsIndex
export def "public-channels GetChannelsIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<channels: record, links: record<channelCountryLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, channelTypeLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, sectorLov: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/channels/")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# The channel list for one country
#
# GET /v2/public/channels/{countryIsoCode}
# operationId: GetChannels
export def "public-channels GetChannels" [
  countryIsoCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: list # Allows the client to indicate whether it accepts a compressed encoding to reduce traffic size.
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<channels: table<homeUrl: string, logoUrl: string, name: string, sectors: list, types: list>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/public/channels/($countryIsoCode)")
  let extra_headers = {"Accept-Encoding": $Accept_Encoding, "If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all list names
#
# GET /v2/public/lov/
# operationId: GetPublicLovIndex
export def "public-lov GetPublicLovIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<lists: record, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/lov/")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the list of values related to this list name
#
# GET /v2/public/lov/{listName}
# operationId: GetPublicListOfValues
export def "public-lov GetPublicListOfValues" [
  listName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: list # Indicates that the client accepts the following languages.
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/public/lov/($listName)")
  let extra_headers = {"Accept-Language": $Accept_Language, "If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Login
#
# POST /v2/public/security/login
# operationId: Login
export def "public-security-login Login" [
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
  let body = {login: $login, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lost password
#
# POST /v2/public/security/lostpassword
# operationId: LostPassword
export def "public-security-lostpassword LostPassword" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# User Registration
#
# POST /v2/public/security/register
# operationId: Register
export def "public-security-register Register" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --commercialOwnerUserId: string # The user id of your commercial in BeezUP. (format: uuid, e.g. 47ea14ab-195d-4f9a-a24e-32c329ee40f6)
  --cultureName: string # Can be null. Default: en-GB. The culture name you want to use. FYI. \ The email activation will use this culture.  (e.g. en-GB)
  email: string # Your email. We refuse disposable email. (e.g. myemail@mycompany.com)
  password: string # The password you want to use for your new account. \ The password length must be greater or equals to 6 and lower or equals to 128. \ The password must contains at least one number and one special character  (e.g. I@mW0nder$Full)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/public/security/register")
  let body = {commercialOwnerUserId: $commercialOwnerUserId, cultureName: $cultureName, email: $email, password: $password} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the Analytics API operation index
#
# GET /v2/user/analytics/
# operationId: AnalyticsIndex
export def "user-analytics AnalyticsIndex" [
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
export def "user-analytics-reports-byday GetStoreReportByDayPerStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advancedFilters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  beginPeriodUtcDate: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalogCategoryId: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channelIds: list # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  endPeriodUtcDate: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --productId: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/analytics/reports/byday")
  let body = {advancedFilters: $advancedFilters, beginPeriodUtcDate: $beginPeriodUtcDate, catalogCategoryId: $catalogCategoryId, channelIds: $channelIds, endPeriodUtcDate: $endPeriodUtcDate, productId: $productId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the global synchronization status of clicks and orders
#
# GET /v2/user/analytics/tracking/status
# operationId: GetTrackingStatus
export def "user-analytics-tracking-status GetTrackingStatus" [
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
export def "user-analytics AnalyticsStoreIndex" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimise all products
#
# POST /v2/user/analytics/{storeId}/optimisations/all/{actionName}
# operationId: OptimiseAll
# --analyticsProductColumnFilters shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
export def "user-analytics-optimisations-all OptimiseAll" [
  storeId: string
  actionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --analyticsProductColumnFilters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --productColumnsToDisplay: list # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  --productState: string@productState-completer # You can filter on the product state. (default: All, e.g. All)
  reportType: string@reportType-completer # The report type (e.g. ByProduct)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/all/($actionName)")
  let body = {analyticsProductColumnFilters: $analyticsProductColumnFilters, productColumnsToDisplay: $productColumnsToDisplay, productState: $productState, reportType: $reportType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Optimise products by category
#
# POST /v2/user/analytics/{storeId}/optimisations/bycategory/{catalogCategoryId}/{actionName}
# operationId: OptimiseByCategory
export def "user-analytics-optimisations-bycategory OptimiseByCategory" [
  storeId: string
  catalogCategoryId: string
  actionName: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/bycategory/($catalogCategoryId)/($actionName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Optimise products by channel
#
# POST /v2/user/analytics/{storeId}/optimisations/bychannel/{channelId}/{actionName}
# operationId: OptimiseByChannel
export def "user-analytics-optimisations-bychannel OptimiseByChannel" [
  storeId: string
  channelId: string
  actionName: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/bychannel/($channelId)/($actionName)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Optimise product
#
# POST /v2/user/analytics/{storeId}/optimisations/byproduct/{productId}/{actionName}
# operationId: OptimiseByProduct
export def "user-analytics-optimisations-byproduct OptimiseByProduct" [
  storeId: string
  productId: string
  actionName: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/byproduct/($productId)/($actionName)")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Copy product optimisations between 2 channels
#
# POST /v2/user/analytics/{storeId}/optimisations/copy
# operationId: CopyOptimisation
export def "user-analytics-optimisations-copy CopyOptimisation" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelIdSource: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  channelIdTarget: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  --keepExistingOptimisation: oneof<nothing, bool> # If true the existing optimisation will be kept (e.g. false)
]: any -> record<catalogProductCount: int, channel: record<channelId: string, channelImageUrl: string, channelName: string>, enabledProductCount: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/copy")
  let body = {channelIdSource: $channelIdSource, channelIdTarget: $channelIdTarget, keepExistingOptimisation: $keepExistingOptimisation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Optimise products by page
#
# POST /v2/user/analytics/{storeId}/optimisations/{actionName}
# operationId: Optimise
export def "user-analytics-optimisations Optimise" [
  storeId: string
  actionName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/optimisations/($actionName)")
  let body = {pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the report by category
#
# POST /v2/user/analytics/{storeId}/reports/bycategory
# operationId: GetStoreReportByCategory
export def "user-analytics-reports-bycategory GetStoreReportByCategory" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> record<categories: table<allProductCount: int, catalogCategoryId: string, catalogCategoryPath: list, catalogProductCount: int, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/bycategory")
  let body = {pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the report by channel
#
# POST /v2/user/analytics/{storeId}/reports/bychannel
# operationId: GetStoreReportByChannel
export def "user-analytics-reports-bychannel GetStoreReportByChannel" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
]: any -> record<channels: table<catalogProductCount: int, channel: record, clickCount: int, cost: float, enabledProductCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, roi: float, soldProductCount: int, totalSales: float>, currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/bychannel")
  let body = {pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the report by day for a StoreId
#
# POST /v2/user/analytics/{storeId}/reports/byday
# operationId: GetStoreReportByDay
# --advancedFilters shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
export def "user-analytics-reports-byday GetStoreReportByDay" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --advancedFilters: record # shape: {globalMarginPercent?: int, linkClickToOrderMaxDay?: int, linkClickToOrderType: "OnPurchaseDate"|"OnClickDate", marginType: "Tracker"|"Global", onlyDirectSales: bool, onlyPaymentValidatedOrders: bool, performanceIndicatorFormula: record}
  beginPeriodUtcDate: string # The begin date of the period for the report (format: date, e.g. 2006-11-20T00:00:00Z)
  --catalogCategoryId: string # The catalog category identifier (format: guid, e.g. 81a058a6-0451-4b79-84ef-94c58d0ed4ac)
  --channelIds: list # Indicate the channel identifier list (e.g. [2dc136a7-0d3d-4cc9-a825-a28a42c53e28])
  endPeriodUtcDate: string # The end date of the period for the report (format: date, e.g. 2006-12-20T00:00:00Z)
  --productId: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
]: any -> record<currencyCode: string, days: table<allChannels: record, byChannels: list, day: string>, globalPerformanceIndicators: record<allChannels: record<performanceIndicator: float>, byChannels: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/byday")
  let body = {advancedFilters: $advancedFilters, beginPeriodUtcDate: $beginPeriodUtcDate, catalogCategoryId: $catalogCategoryId, channelIds: $channelIds, endPeriodUtcDate: $endPeriodUtcDate, productId: $productId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the report by product
#
# POST /v2/user/analytics/{storeId}/reports/byproduct
# operationId: GetStoreReportByProduct
# --analyticsProductColumnFilters shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
export def "user-analytics-reports-byproduct GetStoreReportByProduct" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  --pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --analyticsProductColumnFilters: record # shape: {additionalAnalyticsProductColumnFilters?: record, sku?: string, title?: string}
  --productColumnsToDisplay: list # e.g. [4b460e31-3d1f-4117-922d-b159a64ec1d2]
  productState: string@productState-completer # You can filter on the product state. (default: All, e.g. All)
]: any -> record<currencyCode: string, links: record<disableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, disableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableAllProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, enableProducts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<channelCount: int, clickCount: int, cost: float, enabledOnChannelCount: int, links: record, margin: float, orderCount: int, performanceIndicator: float, product: record, roi: float, soldProductCount: int, totalSales: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/byproduct")
  let body = {pageNumber: $pageNumber, pageSize: $pageSize, analyticsProductColumnFilters: $analyticsProductColumnFilters, productColumnsToDisplay: $productColumnsToDisplay, productState: $productState} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get report filter list for the given store
#
# GET /v2/user/analytics/{storeId}/reports/filters
# operationId: GetReportFilters
export def "user-analytics-reports-filters GetReportFilters" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/filters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the report filter
#
# DELETE /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: DeleteReportFilter
export def "user-analytics-reports-filters DeleteReportFilter" [
  storeId: string
  reportFilterId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/filters/($reportFilterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the report filter description
#
# GET /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: GetReportFilter
export def "user-analytics-reports-filters GetReportFilter" [
  storeId: string
  reportFilterId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/filters/($reportFilterId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save the report filter
#
# PUT /v2/user/analytics/{storeId}/reports/filters/{reportFilterId}
# operationId: SaveReportFilter
export def "user-analytics-reports-filters SaveReportFilter" [
  storeId: string
  reportFilterId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  parameters: any
  reportFilterName: string # Report filter name (e.g. My report filter)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/reports/filters/($reportFilterId)")
  let body = {parameters: $parameters, reportFilterName: $reportFilterName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the list of rules for a given store
#
# GET /v2/user/analytics/{storeId}/rules
# operationId: GetRules
export def "user-analytics-rules GetRules" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Rule creation
#
# POST /v2/user/analytics/{storeId}/rules
# operationId: CreateRule
export def "user-analytics-rules CreateRule" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endUtcDate: string # The end validity utc date of the rule (format: date-time, e.g. 2017-09-30T10:42:40.001Z)
  optimisationActionName: string@optimisationActionName-completer # The optimisation action (e.g. reenable)
  reportFilterId: string # The report filter to use for the rule (format: guid, e.g. fb19c53c-2f63-4262-9d94-2d7faa500acd)
  ruleName: string # The name of the rule (e.g. My rule)
  --startUtcDate: string # The start validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules")
  let body = {endUtcDate: $endUtcDate, optimisationActionName: $optimisationActionName, reportFilterId: $reportFilterId, ruleName: $ruleName, startUtcDate: $startUtcDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the rules execution history
#
# GET /v2/user/analytics/{storeId}/rules/executions
# operationId: GetRulesExecutions
export def "user-analytics-rules-executions GetRulesExecutions" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The page to retrieve (default: 1)
  --pageSize: int # The count of rule history to retrieve (default: 10)
]: nothing -> record<executions: table<activeAffectedProductCount: int, affectedChannelCount: int, affectedProductCount: int, completedUtcDate: string, errorType: string, executionSource: string, links: record, optimisationActionName: string, reportUrl: string, ruleId: string, ruleName: string, startedUtcDate: string, status: string, userId: string>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/executions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run all rules for this store
#
# POST /v2/user/analytics/{storeId}/rules/run
# operationId: RunRules
export def "user-analytics-rules-run RunRules" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/run")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Rule
#
# DELETE /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: DeleteRule
export def "user-analytics-rules DeleteRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the rule
#
# GET /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: GetRule
export def "user-analytics-rules GetRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Rule
#
# PATCH /v2/user/analytics/{storeId}/rules/{ruleId}
# operationId: UpdateRule
export def "user-analytics-rules UpdateRule" [
  storeId: string
  ruleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --endUtcDate: string # Not required. The end validity utc date of the rule (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
  ruleName: string # The name of the rule (e.g. My Rule Renamed)
  --startUtcDate: string # Not required. The start validity utc date of the rule. (format: date-time, e.g. 2016-08-29T09:12:33.001Z)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)")
  let body = {endUtcDate: $endUtcDate, ruleName: $ruleName, startUtcDate: $startUtcDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/disable
# operationId: DisableRule
export def "user-analytics-rules-disable DisableRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/enable
# operationId: EnableRule
export def "user-analytics-rules-enable EnableRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move the rule down
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/movedown
# operationId: MoveDownRule
export def "user-analytics-rules-movedown MoveDownRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)/movedown")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Move the rule up
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/moveup
# operationId: MoveUpRule
export def "user-analytics-rules-moveup MoveUpRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)/moveup")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Run rule
#
# POST /v2/user/analytics/{storeId}/rules/{ruleId}/run
# operationId: RunRule
export def "user-analytics-rules-run RunRule" [
  storeId: string
  ruleId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/rules/($ruleId)/run")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked clicks
#
# GET /v2/user/analytics/{storeId}/tracking/clicks
# operationId: GetStoreTrackedClicks
export def "user-analytics-tracking-clicks GetStoreTrackedClicks" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/tracking/clicks" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked external orders
#
# GET /v2/user/analytics/{storeId}/tracking/externalorders
# operationId: GetStoreTrackedExternalOrders
export def "user-analytics-tracking-externalorders GetStoreTrackedExternalOrders" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/tracking/externalorders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the latest tracked orders
#
# GET /v2/user/analytics/{storeId}/tracking/orders
# operationId: GetStoreTrackedOrders
export def "user-analytics-tracking-orders GetStoreTrackedOrders" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/tracking/orders" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the synchronization status of clicks and orders of a store
#
# GET /v2/user/analytics/{storeId}/tracking/status
# operationId: GetStoreTrackingStatus
export def "user-analytics-tracking-status GetStoreTrackingStatus" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/analytics/($storeId)/tracking/status")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the index of the catalog API
#
# GET /v2/user/catalogs/
# operationId: CatalogIndex
export def "user-catalogs CatalogIndex" [
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
export def "user-catalogs-beezup-columns GetBeezUPColumns" [
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
export def "user-catalogs-importations GetReportingsAllStores" [
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
export def "user-catalogs CatalogStoreIndex" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Auto Import
#
# DELETE /v2/user/catalogs/{storeId}/autoImport
# operationId: Auto_DeleteAutoImport
export def "user-catalogs-auto-import DeleteAutoImport" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto import configuration
#
# GET /v2/user/catalogs/{storeId}/autoImport
# operationId: Auto_GetAutoImportConfiguration
export def "user-catalogs-auto-import GetAutoImportConfiguration" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate the auto importation of the last successful manual catalog importation.
#
# POST /v2/user/catalogs/{storeId}/autoImport/activate
# operationId: Importation_ActivateAutoImport
export def "user-catalogs-auto-import-activate ActivateAutoImport" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/activate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Pause Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/pause
# operationId: Auto_PauseAutoImport
export def "user-catalogs-auto-import-pause PauseAutoImport" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/pause")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resume Auto Import
#
# POST /v2/user/catalogs/{storeId}/autoImport/resume
# operationId: Auto_ResumeAutoImport
export def "user-catalogs-auto-import-resume ResumeAutoImport" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/resume")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure Auto Import Interval
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/interval
# operationId: Auto_ConfigureAutoImportInterval
export def "user-catalogs-auto-import-scheduling-interval ConfigureAutoImportInterval" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/scheduling/interval")
  let body = {interval: $interval} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure Auto Import Schedules
#
# POST /v2/user/catalogs/{storeId}/autoImport/scheduling/schedules
# operationId: Auto_ScheduleAutoImport
export def "user-catalogs-auto-import-scheduling-schedules ScheduleAutoImport" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --localTimeZoneName: string # If null the local time zone name will be "Romance Standard Time" (default: Romance Standard Time, e.g. Romance Standard Time)
  schedules: list # Indicate the time span you want to import your catalog. (i.e. "21:00:00" to import your catalog at 9PM) (e.g. [21:00:00, 23:00:00, 08:30:00])
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/scheduling/schedules")
  let body = {localTimeZoneName: $localTimeZoneName, schedules: $schedules} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start Auto Import Manually
#
# POST /v2/user/catalogs/{storeId}/autoImport/start
# operationId: Auto_StartAutoImport
export def "user-catalogs-auto-import-start StartAutoImport" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/autoImport/start")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get catalog column list
#
# GET /v2/user/catalogs/{storeId}/catalogColumns
# operationId: Catalog_GetCatalogColumns
export def "user-catalogs-catalog-columns GetCatalogColumns" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/catalogColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change Catalog Column User Name
#
# POST /v2/user/catalogs/{storeId}/catalogColumns/{columnId}/rename
# operationId: Catalog_ChangeCatalogColumnUserName
export def "user-catalogs-catalog-columns-rename ChangeCatalogColumnUserName" [
  storeId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userColumName: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/catalogColumns/($columnId)/rename")
  let body = {userColumName: $userColumName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get category list
#
# GET /v2/user/catalogs/{storeId}/categories
# operationId: Catalog_GetCategories
export def "user-catalogs-categories GetCategories" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: list # Indicates that the client accepts that the response will be compressed to reduce traffic size.
]: nothing -> record<categories: table<categoryId: string, categoryPath: list, selfProductCount: int, totalProductCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/categories")
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom column list
#
# GET /v2/user/catalogs/{storeId}/customColumns
# operationId: Catalog_GetCustomColumns
export def "user-catalogs-custom-columns GetCustomColumns" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Compute the expression for this catalog.
#
# POST /v2/user/catalogs/{storeId}/customColumns/computeExpression
# operationId: Catalog_ComputeExpression
export def "user-catalogs-custom-columns-compute-expression ComputeExpression" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encryptedExpression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  productValues: record # The key is the column identifier (e.g. {012929c0-e78b-462a-a96e-25c061575385: http://media.conforama.fr/Medias/500000/80000/5000/500/10/G_585511_A.jpg, 46602e10-bc45-4944-a440-63d5f7ece1f8: 42, 68082b11-4ffd-4bec-964a-465a471c7d37: SKU1234, b6d74510-41ce-42ec-947a-0bdf62e9beee: Refrigerateur, ba270fa0-8482-46be-905a-cae4ca746b92: http://www.conforama.fr/gros-electromenager/encastrable/refrigerateur-encastrable/refrigerateur-combine-161-litres-far-r5115s/p/585511})
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/computeExpression")
  let body = {encryptedExpression: $encryptedExpression, productValues: $productValues} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete custom column
#
# DELETE /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_DeleteCustomColumn
export def "user-catalogs-custom-columns DeleteCustomColumn" [
  storeId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/($columnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}
# operationId: Catalog_SaveCustomColumn
export def "user-catalogs-custom-columns SaveCustomColumn" [
  storeId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  displayGroupName: string # Indicate the display group name where the column must be putted (e.g. Category)
  encryptedBlocklyExpression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encryptedExpression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  userColumnName: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/($columnId)")
  let body = {displayGroupName: $displayGroupName, encryptedBlocklyExpression: $encryptedBlocklyExpression, encryptedExpression: $encryptedExpression, userColumnName: $userColumnName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the encrypted custom column expression
#
# GET /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# operationId: Catalog_GetCustomColumnExpression
export def "user-catalogs-custom-columns-expression GetCustomColumnExpression" [
  storeId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/($columnId)/expression")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change custom column expression
#
# PUT /v2/user/catalogs/{storeId}/customColumns/{columnId}/expression
# operationId: Catalog_ChangeCustomColumnExpression
export def "user-catalogs-custom-columns-expression ChangeCustomColumnExpression" [
  storeId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encryptedBlocklyExpression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encryptedExpression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/($columnId)/expression")
  let body = {encryptedBlocklyExpression: $encryptedBlocklyExpression, encryptedExpression: $encryptedExpression} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change Custom Column User Name
#
# POST /v2/user/catalogs/{storeId}/customColumns/{columnId}/rename
# operationId: Catalog_ChangeCustomColumnUserName
export def "user-catalogs-custom-columns-rename ChangeCustomColumnUserName" [
  storeId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  userColumName: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/customColumns/($columnId)/rename")
  let body = {userColumName: $userColumName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the latest catalog importation reporting
#
# GET /v2/user/catalogs/{storeId}/importations
# operationId: Importation_GetReportings
export def "user-catalogs-importations GetReportings" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations")
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
export def "user-catalogs-importations-start StartManualUpdate" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --duplicateProductSkuConfiguration: record # Describe how you want to manage the duplication of the product value — shape: {compareOptions: "None"|"IgnoreCase"|"IgnoreNonSpace"|"IgnoreSymbols"|"OrdinalIgnoreCase"|"StringSort"|"Ordinal", strategy: "None"|"SkipAllDuplicateProducts"|"KeepFirstDuplicateProductOnly"|"FailImportationIfAnyDuplicateProduct"}
  input: record # Describe the input configuration — shape: {files: list, transformFileUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/start")
  let body = {duplicateProductSkuConfiguration: $duplicateProductSkuConfiguration, input: $input} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the importation status
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}
# operationId: Importation_GetImportationMonitoring
export def "user-catalogs-importations GetImportationMonitoring" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Cancel importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/cancel
# operationId: Importation_Cancel
export def "user-catalogs-importations-cancel Cancel" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/cancel")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get detected catalog columns during this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns
# operationId: Importation_GetDetectedCatalogColumns
export def "user-catalogs-importations-catalog-columns GetDetectedCatalogColumns" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}
# operationId: Importation_ConfigureCatalogColumn
# --catalogColumn shape: {catalogColumnName: string, configuration: record, duplicateProductValueConfiguration?: record, id: string, ignored?: bool, links: record, userColumName: string}
export def "user-catalogs-importations-catalog-columns ConfigureCatalogColumn" [
  storeId: string
  executionId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  catalogColumn: record # The catalog column configuration (e.g. {catalogColumnName: SKU, configuration: {beezUPColumnName: CategoryFirstLevel, canBeTruncated: false, columnCultureName: fr-FR, columnDataType: String, columnFormat: MM/dd/yyyy, columnImportance: Required, displayGroupName: Category}, duplicateProductValueConfiguration: {compareOptions: IgnoreCase, strategy: KeepFirstDuplicateProductOnly}, id: 8a76f06a-fefc-4c0d-bcfe-b210f1482977, ignored: true, userColumName: My SKU}) — shape: {catalogColumnName: string, configuration: record, duplicateProductValueConfiguration?: record, id: string, ignored?: bool, links: record, userColumName: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns/($columnId)")
  let body = {catalogColumn: $catalogColumn} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Ignore Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/ignore
# operationId: Importation_IgnoreColumn
export def "user-catalogs-importations-catalog-columns-ignore IgnoreColumn" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns/($columnId)/ignore")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Map catalog column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/map
# operationId: Importation_MapCatalogColumn
export def "user-catalogs-importations-catalog-columns-map MapCatalogColumn" [
  storeId: string
  executionId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beezUPColumnName: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns/($columnId)/map")
  let body = {beezUPColumnName: $beezUPColumnName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reattend Column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/reattend
# operationId: Importation_ReattendColumn
export def "user-catalogs-importations-catalog-columns-reattend ReattendColumn" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns/($columnId)/reattend")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Unmap catalog column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/catalogColumns/{columnId}/unmap
# operationId: Importation_UnmapCatalogColumn
export def "user-catalogs-importations-catalog-columns-unmap UnmapCatalogColumn" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/catalogColumns/($columnId)/unmap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit Importation
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commit
# operationId: Importation_Commit
export def "user-catalogs-importations-commit Commit" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/commit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Commit columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/commitColumns
# operationId: Importation_CommitColumns
export def "user-catalogs-importations-commit-columns CommitColumns" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/commitColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure remaining catalog columns
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/configureRemainingCatalogColumns
# operationId: Importation_ConfigureRemainingCatalogColumns
export def "user-catalogs-importations-configure-remaining-catalog-columns ConfigureRemainingCatalogColumns" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/configureRemainingCatalogColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get custom columns currently place in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns
# operationId: Importation_GetCustomColumns
export def "user-catalogs-importations-custom-columns GetCustomColumns" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Custom Column
#
# DELETE /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_DeleteCustomColumn
export def "user-catalogs-importations-custom-columns DeleteCustomColumn" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns/($columnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create or replace a custom column
#
# PUT /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}
# operationId: Importation_SaveCustomColumn
export def "user-catalogs-importations-custom-columns SaveCustomColumn" [
  storeId: string
  executionId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  encryptedBlocklyExpression: string # The encrypted XML Blockly representation of the expression (e.g. apokpoa,opz,sixsoisiosnoisn)
  encryptedExpression: string # The encrypted excel expression of the column (e.g. uziushdczaniodnndonisodndsiondsoidsndoin)
  userColumName: string # Column named by the user (e.g. My SKU)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns/($columnId)")
  let body = {encryptedBlocklyExpression: $encryptedBlocklyExpression, encryptedExpression: $encryptedExpression, userColumName: $userColumName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the encrypted custom column expression in this importation
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/expression
# operationId: Importation_GetCustomColumnExpression
export def "user-catalogs-importations-custom-columns-expression GetCustomColumnExpression" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns/($columnId)/expression")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Map custom column to a BeezUP column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/map
# operationId: Importation_MapCustomColumn
export def "user-catalogs-importations-custom-columns-map MapCustomColumn" [
  storeId: string
  executionId: string
  columnId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beezUPColumnName: string # The BeezUP column name (e.g. CategoryFirstLevel)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns/($columnId)/map")
  let body = {beezUPColumnName: $beezUPColumnName} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unmap custom column
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/customColumns/{columnId}/unmap
# operationId: Importation_UnmapCustomColumn
export def "user-catalogs-importations-custom-columns-unmap UnmapCustomColumn" [
  storeId: string
  executionId: string
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/customColumns/($columnId)/unmap")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the product sample related to this importation with all columns (catalog and custom)
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}
# operationId: Importation_GetProductSample
export def "user-catalogs-importations-product-samples GetProductSample" [
  storeId: string
  executionId: string
  productSampleIndex: int
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/productSamples/($productSampleIndex)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product sample custom column value related to this importation.
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/productSamples/{productSampleIndex}/customColumns/{columnId}
# operationId: Importation_GetProductSampleCustomColumnValue
export def "user-catalogs-importations-product-samples-custom-columns GetProductSampleCustomColumnValue" [
  storeId: string
  executionId: string
  productSampleIndex: int
  columnId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/productSamples/($productSampleIndex)/customColumns/($columnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Importation Get Products Report
#
# POST /v2/user/catalogs/{storeId}/importations/{executionId}/products/list
# operationId: Importation_GetProductsReport
# --errorCodes item shape: {errorCode?: string, userColumnName?: string}
export def "user-catalogs-importations-products-list GetProductsReport" [
  storeId: string
  executionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --ean: string # Filter by EAN (equals)
  --errorCodes: list # Get Importation Products Report Request Error Codes — item shape: {errorCode?: string, userColumnName?: string}
  --mpn: string # Filter by MPN (equals)
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --sku: string # Filter by Sku (equals)
  --title: string # Filter by Title (StartsWith)
]: any -> record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productErrors: table<ean: string, errors: list, lineNumber: int, mpn: string, sku: string, title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/products/list")
  let body = {ean: $ean, errorCodes: $errorCodes, mpn: $mpn, pageNumber: $pageNumber, pageSize: $pageSize, sku: $sku, title: $title} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Importation Get Report
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/report
# operationId: Importation_GetReport
export def "user-catalogs-importations-report GetReport" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/report")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get technical progression
#
# GET /v2/user/catalogs/{storeId}/importations/{executionId}/technicalProgression
# operationId: Importation_TechnicalProgression
export def "user-catalogs-importations-technical-progression TechnicalProgression" [
  storeId: string
  executionId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/importations/($executionId)/technicalProgression")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the last input configuration
#
# GET /v2/user/catalogs/{storeId}/inputConfiguration
# operationId: Importation_GetManualUpdateLastInputConfig
export def "user-catalogs-input-configuration GetManualUpdateLastInputConfig" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/inputConfiguration")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product by Sku
#
# GET /v2/user/catalogs/{storeId}/products
# operationId: Catalog_GetProductBySku
export def "user-catalogs-products GetProductBySku" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/products" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product list
#
# POST /v2/user/catalogs/{storeId}/products/list
# operationId: Catalog_GetProducts
export def "user-catalogs-products-list GetProducts" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --categoryPath: list # The catalog category path (e.g. [Vêtements, Femmes, Chaussures])
  --columnIdList: list
  --ean: string # Search for product by ean (e.g. MySku123)
  --exists: oneof<nothing, bool> # Search for existing products or not. If null you will received both. (e.g. true)
  --mpn: string # Search for product by mpn (e.g. MySku123)
  --orderByCatalogColumnId: string # The catalog column identifier (catalog or custom column) (format: guid, e.g. bea7c21e-948b-4ac3-9ffd-4396e62c4163)
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the item count per page (format: int32, default: 100, e.g. 100)
  --productIdList: list # Filter with a list of product identifier
  --sku: string # Search for product by sku (e.g. MySku123)
  --title: string # Search for products containing this title (e.g. Frigo)
  --withoutSubCategories: oneof<nothing, bool> # Do not retrieve sub categories. By default, this value is set to false (e.g. false)
]: any -> record<paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, products: table<categoryId: string, exists: bool, productId: string, values: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/products/list")
  let body = {categoryPath: $categoryPath, columnIdList: $columnIdList, ean: $ean, exists: $exists, mpn: $mpn, orderByCatalogColumnId: $orderByCatalogColumnId, pageNumber: $pageNumber, pageSize: $pageSize, productIdList: $productIdList, sku: $sku, title: $title, withoutSubCategories: $withoutSubCategories} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get random product list
#
# GET /v2/user/catalogs/{storeId}/products/random
# operationId: Catalog_GetRandomProducts
export def "user-catalogs-products-random GetRandomProducts" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/products/random")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get product by ProductId
#
# GET /v2/user/catalogs/{storeId}/products/{productId}
# operationId: Catalog_GetProductByProductId
export def "user-catalogs-products GetProductByProductId" [
  storeId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/catalogs/($storeId)/products/($productId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# List all your current channel catalogs
#
# GET /v2/user/channelCatalogs/
# operationId: GetChannelCatalogs
export def "user-channel-catalogs GetChannelCatalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<channelCatalogs: record, links: record<add: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, beezUPColumns: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, filterOperators: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<channelCatalogExclusionFilterOperatorLov: record<href: string, method: string>, channelCatalogExportCacheStatusLov: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/channelCatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a new channel catalog
#
# POST /v2/user/channelCatalogs/
# operationId: AddChannelCatalog
export def "user-channel-catalogs AddChannelCatalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelId: string # The channel identifier (format: guid, e.g. 2dc136a7-0d3d-4cc9-a825-a28a42c53e28)
  storeId: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/channelCatalogs/")
  let body = {channelId: $channelId, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channel catalog filter operators
#
# GET /v2/user/channelCatalogs/filterOperators
# operationId: GetChannelCatalogFilterOperators
export def "user-channel-catalogs-filter-operators GetChannelCatalogFilterOperators" [
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
export def "user-channel-catalogs-products GetChannelCatalogProductByChannelCatalog" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelCatalogIds: list # The list of channel catalog identifier
  productId: string # The product identifier (format: guid, e.g. 578419df-1bbf-41a6-96fa-862e42182b67)
  storeId: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> record<channelCatalogs: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/channelCatalogs/products")
  let body = {channelCatalogIds: $channelCatalogIds, productId: $productId, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the channel catalog
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}
# operationId: DeleteChannelCatalog
export def "user-channel-catalogs DeleteChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the channel catalog information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}
# operationId: GetChannelCatalog
export def "user-channel-catalogs GetChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog categories
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/categories
# operationId: GetChannelCatalogCategories
export def "user-channel-catalogs-categories GetChannelCatalogCategories" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/categories")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog category
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/configure
# operationId: ConfigureChannelCatalogCategory
# --channelCatalogCategories item shape: {autoMapNewSubCategories: bool, catalogCategoryPath: list, channelCategoryPath?: list, costValue?: float}
export def "user-channel-catalogs-categories-configure ConfigureChannelCatalogCategory" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  channelCatalogCategories: list # item shape: {autoMapNewSubCategories: bool, catalogCategoryPath: list, channelCategoryPath?: list, costValue?: float}
  --overrideSubCategoryMappings: oneof<nothing, bool> # Great feature! In case of mapping to parent channel category, you can ask to override the mapping of all sub channel category to this catalog category path (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/categories/configure")
  let body = {channelCatalogCategories: $channelCatalogCategories, overrideSubCategoryMappings: $overrideSubCategoryMappings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/disableMapping
# operationId: DisableChannelCatalogCategoryMapping
export def "user-channel-catalogs-categories-disable-mapping DisableChannelCatalogCategoryMapping" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/categories/disableMapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reenable a channel catalog category mapping
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/categories/reenableMapping
# operationId: ReenableChannelCatalogCategoryMapping
export def "user-channel-catalogs-categories-reenable-mapping ReenableChannelCatalogCategoryMapping" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/categories/reenableMapping")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog column mappings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/columnMappings
# operationId: ConfigureChannelCatalogColumnMappings
export def "user-channel-catalogs-column-mappings ConfigureChannelCatalogColumnMappings" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/columnMappings")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Disable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/disable
# operationId: DisableChannelCatalog
export def "user-channel-catalogs-disable DisableChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Enable a channel catalog
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/enable
# operationId: EnableChannelCatalog
export def "user-channel-catalogs-enable EnableChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/enable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog exclusion filters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# operationId: GetChannelCatalogExclusionFilters
export def "user-channel-catalogs-exclusion-filters GetChannelCatalogExclusionFilters" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/exclusionFilters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog exclusion filters
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/exclusionFilters
# operationId: ConfigureChannelCatalogExclusionFilters
export def "user-channel-catalogs-exclusion-filters ConfigureChannelCatalogExclusionFilters" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/exclusionFilters")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the exportation cache information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache
# operationId: GetChannelCatalogExportationCacheInfo
export def "user-channel-catalogs-exportations-cache GetChannelCatalogExportationCacheInfo" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/exportations/cache")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Clear the exportation cache
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/exportations/cache/clear
# operationId: ClearChannelCatalogExportationCache
export def "user-channel-catalogs-exportations-cache-clear ClearChannelCatalogExportationCache" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/exportations/cache/clear")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the exportation history
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/exportations/history
# operationId: GetChannelCatalogExportationHistory
export def "user-channel-catalogs-exportations-history GetChannelCatalogExportationHistory" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The page number you want to get (format: int32, e.g. 1)
  --pageSize: int # The entry count you want to get (format: int32, e.g. 25)
]: nothing -> record<exportations: table<cacheStatus: string, clientIpAddress: string, clientUserAgent: string, exportationDuration: string, exportationUtcDate: string, exportedProductCount: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/exportations/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products
# operationId: GetChannelCatalogProductInfoList
# --catalogCategoryFilter shape: {categoryPath?: list}
# --channelCategoryFilter shape: {categoryPath?: list}
# --criteria shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
# --productFilters shape: {additionalProductFilters?: record, catalogEans?: list, catalogMpns?: list, catalogSkus?: list, channelEans?: list, channelMpns?: list, channelSkus?: list, title?: string}
export def "user-channel-catalogs-products GetChannelCatalogProductInfoList" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --catalogCategoryFilter: record # shape: {categoryPath?: list}
  --channelCategoryFilter: record # shape: {categoryPath?: list}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  pageNumber: int # format: int32, e.g. 1
  pageSize: int # format: int32, e.g. 100
  --productFilters: record # shape: {additionalProductFilters?: record, catalogEans?: list, catalogMpns?: list, catalogSkus?: list, channelEans?: list, channelMpns?: list, channelSkus?: list, title?: string}
]: any -> record<links: record<export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>, productInfos: table<productExists: bool, productId: string, productImageUrl: string, productSku: string, productTitle: string, disabled: bool, excluded: bool, excludedBy: list, links: record, overrides: record, uncategorized: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products")
  let body = {catalogCategoryFilter: $catalogCategoryFilter, channelCategoryFilter: $channelCategoryFilter, criteria: $criteria, overridden: $overridden, pageNumber: $pageNumber, pageSize: $pageSize, productFilters: $productFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channel catalog products' counters
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/counters
# operationId: GetChannelCatalogProductsCounters
export def "user-channel-catalogs-products-counters GetChannelCatalogProductsCounters" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/counters")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Export channel catalog product information list
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/export
# operationId: ExportChannelCatalogProductInfoList
# --catalogCategoryFilter shape: {categoryPath?: list}
# --channelCategoryFilter shape: {categoryPath?: list}
# --criteria shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
# --productFilters shape: {additionalProductFilters?: record, catalogEans?: list, catalogMpns?: list, catalogSkus?: list, channelEans?: list, channelMpns?: list, channelSkus?: list, title?: string}
export def "user-channel-catalogs-products-export ExportChannelCatalogProductInfoList" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer # The file type of the exportation
  --catalogCategoryFilter: record # shape: {categoryPath?: list}
  --channelCategoryFilter: record # shape: {categoryPath?: list}
  criteria: record # shape: {disabled?: bool, excluded?: bool, exist?: bool, logic: "funnel"|"cumulative", uncategorized?: bool}
  --overridden: oneof<nothing, bool> # Search overridden products. If null the filter will not be taken in account. (e.g. true)
  pageNumber: int # format: int32, e.g. 1
  pageSize: int # format: int32, e.g. 100
  --productFilters: record # shape: {additionalProductFilters?: record, catalogEans?: list, catalogMpns?: list, catalogSkus?: list, channelEans?: list, channelMpns?: list, channelSkus?: list, title?: string}
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "format" $format "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/export" $qp)
  let body = {catalogCategoryFilter: $catalogCategoryFilter, channelCategoryFilter: $channelCategoryFilter, criteria: $criteria, overridden: $overridden, pageNumber: $pageNumber, pageSize: $pageSize, productFilters: $productFilters} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channel catalog product information
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}
# operationId: GetChannelCatalogProductInfo
export def "user-channel-catalogs-products GetChannelCatalogProductInfo" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/disable
# operationId: DisableChannelCatalogProduct
export def "user-channel-catalogs-products-disable DisableChannelCatalogProduct" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/disable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Override channel catalog product values
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides
# operationId: OverrideChannelCatalogProductValues
export def "user-channel-catalogs-products-overrides OverrideChannelCatalogProductValues" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/overrides")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get channel catalog product value override compatibilities status
#
# GET /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: GetChannelCatalogProductValueOverrideCopy
export def "user-channel-catalogs-products-overrides-copy GetChannelCatalogProductValueOverrideCopy" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/overrides/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Copy channel catalog product value override
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/copy
# operationId: ConfigureChannelCatalogProductValueOverrideCopy
export def "user-channel-catalogs-products-overrides-copy ConfigureChannelCatalogProductValueOverrideCopy" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/overrides/copy")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a specific channel catalog product value override
#
# DELETE /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/overrides/{channelColumnId}
# operationId: DeleteChannelCatalogProductValueOverride
export def "user-channel-catalogs-products-overrides DeleteChannelCatalogProductValueOverride" [
  channelCatalogId: string
  productId: string
  channelColumnId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/overrides/($channelColumnId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Reenable channel catalog product
#
# POST /v2/user/channelCatalogs/{channelCatalogId}/products/{productId}/reenable
# operationId: ReenableChannelCatalogProduct
export def "user-channel-catalogs-products-reenable ReenableChannelCatalogProduct" [
  channelCatalogId: string
  productId: string
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
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/products/($productId)/reenable")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure channel catalog cost settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/cost
# operationId: ConfigureChannelCatalogCostSettings
export def "user-channel-catalogs-settings-cost ConfigureChannelCatalogCostSettings" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  costType: string@costType-completer # CPC means cost per click. CPA means cost per action. You can have CPC/CPA with a global cost value. You can have CPC/CPA by category the cost value MUST be null You can have global fixed price.  (e.g. Fixed_Global)
  --globalCostValue: float # In case of global cost type, you have to indicate the cost value. (format: decimal, e.g. 10.21)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/settings/cost")
  let body = {costType: $costType, globalCostValue: $globalCostValue} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Configure channel catalog general settings
#
# PUT /v2/user/channelCatalogs/{channelCatalogId}/settings/general
# operationId: ConfigureChannelCatalogGeneralSettings
export def "user-channel-catalogs-settings-general ConfigureChannelCatalogGeneralSettings" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptToPublishInfo: oneof<nothing, bool> # If true then you authorize disclosure of my statistics generated from clicks and sales (e.g. true)
  --activeBeezUPTracking: oneof<nothing, bool> # Activate BeezUP tracking for my statistics (checked by default) (default: true, e.g. true)
  --doNotExportOutOfStockProducts: oneof<nothing, bool> # Do not export "out of stock" products. Note: this option is not taken into account by the counter.  (e.g. true)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channelCatalogs/($channelCatalogId)/settings/general")
  let body = {acceptToPublishInfo: $acceptToPublishInfo, activeBeezUPTracking: $activeBeezUPTracking, doNotExportOutOfStockProducts: $doNotExportOutOfStockProducts} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List all available channel for this store
#
# GET /v2/user/channels/
# operationId: GetAvailableChannels
export def "user-channels GetAvailableChannels" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> table<channelId: string, channelLogoUrl: string, channelName: string, links: record<self: record>, types: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/channels/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel information
#
# GET /v2/user/channels/{channelId}
# operationId: GetChannelInfo
export def "user-channels GetChannelInfo" [
  channelId: string
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
  let full_url = (build-url $base $"/v2/user/channels/($channelId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel categories
#
# GET /v2/user/channels/{channelId}/categories
# operationId: GetChannelCategories
export def "user-channels-categories GetChannelCategories" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: list # Indicates that the client accepts that the response will be compressed to reduce traffic size.
]: nothing -> record<firstLevelCategories: table<channelCategoryChannelCode: string, channelCategoryColumnOverrides: record, channelCategoryDefaultCost: float, channelCategoryId: string, channelCategoryLevel: int, channelCategoryName: string, subCategories: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channels/($channelId)/categories")
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get channel columns
#
# POST /v2/user/channels/{channelId}/columns
# operationId: GetChannelColumns
export def "user-channels-columns GetChannelColumns" [
  channelId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: list # Indicates that the client accepts that the response will be compressed to reduce traffic size.
  --body: record
]: any -> table<channelColumnDescription: string, channelColumnId: string, channelColumnName: string, configuration: record<beezUPColumnName: string, columnDataType: string, columnImportance: string>, position: int, restrictedValues: record, showInMapping: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/channels/($channelId)/columns")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# The index of all operations and LOV
#
# GET /v2/user/customer/
# operationId: GetCustomerIndex
export def "user-customer GetCustomerIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<accountInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, billingPeriods: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, friendInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getOffer: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, invoices: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, logout: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, standardOffers: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, stores: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<activeOfferLov: record<href: string, method: string>, beezUPTimeZoneLov: record<href: string, method: string>, contractTerminationReasonLov: record<href: string, method: string>, countryLov: record<href: string, method: string>, customerStatusLov: record<href: string, method: string>, invoicePaymentStatusLov: record<href: string, method: string>, offerLov: record<href: string, method: string>, storeCountryLov: record<href: string, method: string>, storeSectorLov: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user account information
#
# GET /v2/user/customer/account
# operationId: GetUserAccountInfo
export def "user-customer-account GetUserAccountInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<commercialOwnerEmail: string, companyInfo: record<accountingEmails: list<string>, address: string, city: string, company: string, countryIsoCodeAlpha3: string, postalCode: string, vatNumber: string>, email: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<activateUserAccount: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changeEmail: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, changePassword: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, getProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCompanyInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, savePersonalInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, saveProfilePictureInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, personalInfo: record<beezUPTimeZoneId: int, firstName: string, lastName: string, phoneNumber: string, whatIDo: string>, profilePictureUrl: string, status: string, userId: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Activate the user account
#
# POST /v2/user/customer/account/activate
# operationId: ActivateUserAccount
export def "user-customer-account-activate ActivateUserAccount" [
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
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change user email
#
# POST /v2/user/customer/account/changeEmail
# operationId: ChangeEmail
export def "user-customer-account-change-email ChangeEmail" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  newEmail: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/changeEmail")
  let body = {newEmail: $newEmail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change user password
#
# POST /v2/user/customer/account/changePassword
# operationId: ChangePassword
export def "user-customer-account-change-password ChangePassword" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  newPassword: string # Your new password. Which must respect the same constraints as the user registeration (format: password)
  oldPassword: string # Your current password (format: password)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/changePassword")
  let body = {newPassword: $newPassword, oldPassword: $oldPassword} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change company information
#
# PUT /v2/user/customer/account/companyInfo
# operationId: SaveCompanyInfo
export def "user-customer-account-company-info SaveCompanyInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountingEmails: list # Your company accounting emails (e.g. [myaccountemail@mysupercompany.com])
  address: string # Your address (e.g. 21 jump street)
  city: string # Your address city (e.g. New-York)
  company: string # Your company name (e.g. My super company)
  countryIsoCodeAlpha3: string # The country iso code alpha 3 <a href="https://en.wikipedia.org/wiki/ISO_3166-1_alpha-3">(ISO 3166-1_alpha-3)</a> (e.g. FRA)
  postalCode: string # Your address postal code (e.g. 13014)
  --vatNumber: string # Your company VATNumber. Used for french company. This number is checked with official web service before being saved. (e.g. 1234567890)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/companyInfo")
  let body = {accountingEmails: $accountingEmails, address: $address, city: $city, company: $company, countryIsoCodeAlpha3: $countryIsoCodeAlpha3, postalCode: $postalCode, vatNumber: $vatNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get credit card information
#
# GET /v2/user/customer/account/creditCardInfo
# operationId: GetCreditCardInfo
export def "user-customer-account-credit-card-info GetCreditCardInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<creditCardInfo: record<cardNumber: string, cardType: string, expirationMonth: int, expirationYear: int>, currentPaymentMethod: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<saveCreditCardInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/creditCardInfo")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save user credit card info
#
# PUT /v2/user/customer/account/creditCardInfo
# operationId: SaveCreditCardInfo
export def "user-customer-account-credit-card-info SaveCreditCardInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cardNumber: string # Card number (e.g. 1234567890091234)
  cardVerificationCode: string # Card Verification Code (e.g. 123)
  expirationMonth: int # Expiration Month (format: int32, e.g. 12)
  expirationYear: int # Expiration Year (format: int32, e.g. 2017)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/creditCardInfo")
  let body = {cardNumber: $cardNumber, cardVerificationCode: $cardVerificationCode, expirationMonth: $expirationMonth, expirationYear: $expirationYear} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Save user personal information
#
# PUT /v2/user/customer/account/personalInfo
# operationId: SavePersonalInfo
export def "user-customer-account-personal-info SavePersonalInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  beezUPTimeZoneId: int # The time zone identifier based on the list of values /v2/user/lov/BeezUPTimeZone (format: int32, e.g. 79)
  firstName: string # Your first name (e.g. Paul)
  lastName: string # Your last name (e.g. Simon)
  phoneNumber: string # Your phone number (e.g. 5551234)
  --whatIDo: string # Your role in your company (e.g. I'm the Manager on this company)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/personalInfo")
  let body = {beezUPTimeZoneId: $beezUPTimeZoneId, firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber, whatIDo: $whatIDo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get profile picture information
#
# GET /v2/user/customer/account/profilePictureInfo
# operationId: GetProfilePictureInfo
export def "user-customer-account-profile-picture-info GetProfilePictureInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<save: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, profilePictureInfo: record<profilePictureSelected: string, profilePictureUrl: string, gravatarProfilePictureUrl: string, initialsProfilePictureUrl: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/profilePictureInfo")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Change user picture information
#
# PUT /v2/user/customer/account/profilePictureInfo
# operationId: SaveProfilePictureInfo
export def "user-customer-account-profile-picture-info SaveProfilePictureInfo" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  profilePictureSelected: string@profilePictureSelected-completer # Your profile picture choice about usage of gravatar picture, initials picture or uploaded picture. (e.g. initials)
  --profilePictureUrl: string # Indicate the url of your picture profil (e.g. https://upload.wikimedia.org/wikipedia/commons/thumb/e/e5/Marlon_Brando_%28cropped%29.jpg/220px-Marlon_Brando_%28cropped%29.jpg)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/account/profilePictureInfo")
  let body = {profilePictureSelected: $profilePictureSelected, profilePictureUrl: $profilePictureUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Resend email activation
#
# POST /v2/user/customer/account/resendEmailActivation
# operationId: ResendEmailActivation
export def "user-customer-account-resend-email-activation ResendEmailActivation" [
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
export def "user-customer-billing-periods GetBillingPeriods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<billingPeriods: table<billingPeriodInMonth: int, discountPercentage: float>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/billingPeriods")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get contract list
#
# GET /v2/user/customer/contracts
# operationId: GetContracts
export def "user-customer-contracts GetContracts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<current: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<disable: record, reenable: record>>, links: record<create: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, next: record<additionalClickPrice: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float, clickIncluded: int, commitmentCalculatedFinishUtcDate: string, commitmentPeriodInMonth: int, contractId: string, currencyCode: string, discountDurationInMonth: int, discountEndUtcDate: string, fixedAndVariableClickInfo: record<clickIncludedAndAdditionalClickPrices: list>, fixedPrice: float, ipUserCreation: string, ipUserModification: string, isCommitmentRenewalAutomatically: bool, isModifiableContract: bool, offerId: int, offerName: string, percentDiscount: float, startUtcDate: string, storeCount: int, trialPeriodInMonth: int, variableModelInfo: record<clickIncludedAndVariablePrices: list, overflowClickCount: int, overflowClickPrice: float>, links: record<delete: record>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new contract
#
# POST /v2/user/customer/contracts
# operationId: CreateContract
export def "user-customer-contracts CreateContract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  billingPeriodInMonth: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --couponDiscountCode: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --couponOfferCode: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offerId: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  storeCount: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<contracts: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts")
  let body = {billingPeriodInMonth: $billingPeriodInMonth, couponDiscountCode: $couponDiscountCode, couponOfferCode: $couponOfferCode, offerId: $offerId, storeCount: $storeCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Schedule termination of your current contract at the end of the commitment.
#
# POST /v2/user/customer/contracts/current/disableAutoRenewal
# operationId: TerminateCurrentContract
export def "user-customer-contracts-current-disable-auto-renewal TerminateCurrentContract" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --contractTerminationReason: string # The termination reason, if your current contract is scheduled to be terminated. (e.g. I'm crazy, I want to leave your splendid service...)
  contractTerminationReasonType: int # The contract termination reason type identifier, if your current contract is scheduled to be terminated. The value is based on the list of values /user/lov/ContractTerminationReason (format: int32, e.g. 1)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/contracts/current/disableAutoRenewal")
  let body = {contractTerminationReason: $contractTerminationReason, contractTerminationReasonType: $contractTerminationReasonType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reactivate your terminated contract.
#
# POST /v2/user/customer/contracts/current/reenableAutoRenewal
# operationId: ReactivateCurrentContract
export def "user-customer-contracts-current-reenable-auto-renewal ReactivateCurrentContract" [
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
export def "user-customer-contracts-next DeleteNextContract" [
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
export def "user-customer-friends GetFriendInfo" [
  userId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<company: string, countryIsoCodeAlpha3: string, email: string, firstName: string, lastName: string, profilePictureUrl: string, userId: string, whatIDo: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/customer/friends/($userId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all your invoices
#
# GET /v2/user/customer/invoices
# operationId: GetInvoices
export def "user-customer-invoices GetInvoices" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<invoices: table<amount: float, amountToBePaid: float, contractId: string, currencyCode: string, dueDate: string, invoiceDate: string, invoiceNumber: string, invoiceUrl: string, paymentStatus: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/invoices")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all standard offers
#
# GET /v2/user/customer/offers
# operationId: GetStandardOffers
export def "user-customer-offers GetStandardOffers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<functionalities: table<code: string, order: int>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, offers: table<additionalClickPrice: float, currencyCode: string, fixedPrice: float, functionalities: list, includedClick: int, isMostPopular: bool, isOldOffer: bool, links: record, name: string, offerId: int, position: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/offers")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get offer pricing
#
# POST /v2/user/customer/offers
# operationId: GetOffer
export def "user-customer-offers GetOffer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  billingPeriodInMonth: int # Can be null. The billing period in month based on /billingPeriods (format: int32, e.g. 12)
  --couponDiscountCode: string # The coupon discount code (e.g. I-LOVE-BEEZUP)
  --couponOfferCode: string # Your special coupon offer identifier (format: guid, e.g. 04efc310-bc25-4710-a83a-faf200284fe5)
  offerId: int # The offer id based on /offers. Not a free offer of course. (format: int32, e.g. 1)
  storeCount: int # The store count you want to have in your contract. (format: int32, e.g. 1)
]: any -> record<content: record<contractBillingPeriodInfo: record<amountBillingPeriodDiscount: float, billingPeriodInMonth: int, billingPeriodPercentDiscount: float>, contractBonusInfo: record<bonuses: list>, contractClickInfo: record<additionalClickPrice: float, clickIncluded: int, initialOfferClickIncluded: int>, contractCommitmentInfo: record<commercialCreatorUserId: string, commercialUserId: string, commitmentCalculatedFinishDate: string, commitmentPeriodInMonth: int, contractType: int, couponOfferCode: string, currentContractId: string, currentContractTerminationDate: string, currentCustomerPaymentMethod: string, fixedAndVariableClickInfo: record, isCustomerWantsToTerminateHisContract: bool, isModelMustBeTransmittedInNewContract: bool, minBillingPeriodInMonths: int, model: string, newContractStartDate: string, offerId: int, offerName: string, paymentDelayInDays: int, paymentMethodAuthorized: string, requestedPaymentMethod: string, trialPeriodFinishDate: string, trialPeriodInMonth: int, variableModelInfo: record>, contractDiscountInfo: record<amountCodePromoDiscount: float, amountCodePromoDiscountPerMonth: float, couponDiscountCode: string, couponDiscountId: int, customerHasActualDiscount: bool, discountDurationInMonth: int, isCouponDiscountLinkedToCouponOffer: bool, percentDiscount: float, promotionalCodeValidity: string>, contractMoneyInfo: record<amountExcludingTaxesAndExcludingCodePromoDiscountIncludingBillingPeriodDiscount: float, amountExcludingTaxesAndExcludingDiscounts: float, amountExcludingTaxesIncludingDiscounts: float, amountExcludingTaxesIncludingDiscountsPerMonth: float, amountIncludingTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountIncludingTaxesIncludingDiscounts: float, amountTaxesExcludingDiscountIncludingBillingPeriodDiscount: float, amountTaxesIncludingDiscounts: float, currencyCode: string, initialOfferFixedPrice: float, vatPercent: float>, contractStoreInfo: record<additionalStorePrice: float, maxStoreCount: int, minStoreCount: int, ownedStoreCount: int, storeCount: int, storeIncluded: int>, contractTerminationReason: string, contractTerminationReasonType: int, notifyVatExemption: bool, previousFixPeriodInvoiceProrataInfo: record<amountAfterTax: float, amountToBePaid: float, computedProrataToBeDeducted: float, contractId: string, fixedPeriodEndDate: string, fixedPeriodStartDate: string, invoiceNumber: string>>, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<createContract: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/offers")
  let body = {billingPeriodInMonth: $billingPeriodInMonth, couponDiscountCode: $couponDiscountCode, couponOfferCode: $couponOfferCode, offerId: $offerId, storeCount: $storeCount} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Log out the current user from go2
#
# POST /v2/user/customer/security/logout
# operationId: Logout
export def "user-customer-security-logout Logout" [
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
export def "user-customer-stores GetStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<createStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, stores: table<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list, shareCount: int, status: string, storeId: string, url: string, userRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/stores")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new store
#
# POST /v2/user/customer/stores
# operationId: CreateStore
export def "user-customer-stores CreateStore" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  countryIsoCodeAlpha3: string # The country iso code alpha 3 based on the list of values /user/lov/StoreCountry (e.g. DEU)
  --id: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  --body-url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/customer/stores")
  let body = {countryIsoCodeAlpha3: $countryIsoCodeAlpha3, id: $id, name: $name, sectors: $sectors, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a store
#
# DELETE /v2/user/customer/stores/{storeId}
# operationId: DeleteStore
export def "user-customer-stores DeleteStore" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get store's information
#
# GET /v2/user/customer/stores/{storeId}
# operationId: GetStore
export def "user-customer-stores GetStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<countryIsoCodeAlpha3: string, creationUtcDate: string, currencyCode: string, goVersion: int, isTest: bool, links: record<deleteStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, shares: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, updateStore: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, name: string, offerId: int, offerName: string, ownerUserId: string, sectors: list<string>, shareCount: int, status: string, storeId: string, url: string, userRole: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update some store's information.
#
# PATCH /v2/user/customer/stores/{storeId}
# operationId: UpdateStore
export def "user-customer-stores UpdateStore" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  name: string # The store name. Must be unique. (e.g. My Store)
  sectors: list # The store's sectors based on the list of values /user/lov/ParamSector (e.g. [ANIMALERIE, AUTOMOTO])
  --body-url: string # The url of your store (e.g. http://www.mystore.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)")
  let body = {name: $name, sectors: $sectors, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store's alerts
#
# GET /v2/user/customer/stores/{storeId}/alerts
# operationId: GetStoreAlerts
export def "user-customer-stores-alerts GetStoreAlerts" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<alerts: table<alertId: int, alertName: string, enabled: bool, links: record, properties: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/alerts")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save store alerts
#
# POST /v2/user/customer/stores/{storeId}/alerts
# operationId: SaveStoreAlerts
export def "user-customer-stores-alerts SaveStoreAlerts" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/alerts")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get store's rights
#
# GET /v2/user/customer/stores/{storeId}/rights
# operationId: GetRights
export def "user-customer-stores-rights GetRights" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/rights")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get shares related to this store
#
# GET /v2/user/customer/stores/{storeId}/shares
# operationId: GetStoreShares
export def "user-customer-stores-shares GetStoreShares" [
  storeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, share: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, shares: table<links: record, userId: string, userRole: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/shares")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Share a store to another user
#
# POST /v2/user/customer/stores/{storeId}/shares
# operationId: ShareStore
export def "user-customer-stores-shares ShareStore" [
  storeId: string
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
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/shares")
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a share of a store to another user
#
# DELETE /v2/user/customer/stores/{storeId}/shares/{userId}
# operationId: DeleteStoreShare
export def "user-customer-stores-shares DeleteStoreShare" [
  storeId: string
  userId: string
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
  let full_url = (build-url $base $"/v2/user/customer/stores/($storeId)/shares/($userId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Zendesk token
#
# GET /v2/user/customer/zendeskToken
# operationId: ZendeskToken
export def "user-customer-zendesk-token ZendeskToken" [
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
export def "user-legacy-tracking-channel-catalogs GetLegacyTrackingChannelCatalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The store identifier (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<channelCatalogs: record, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/legacyTracking/channelCatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the channel catalog configured to use legacy tracking format information
#
# GET /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}
# operationId: GetLegacyTrackingChannelCatalog
export def "user-legacy-tracking-channel-catalogs GetLegacyTrackingChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/legacyTracking/channelCatalogs/($channelCatalogId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Migrate a channel catalog to current tracking format
#
# POST /v2/user/legacyTracking/channelCatalogs/{channelCatalogId}/migrate
# operationId: MigrateLegacyTrackingChannelCatalog
export def "user-legacy-tracking-channel-catalogs-migrate MigrateLegacyTrackingChannelCatalog" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/legacyTracking/channelCatalogs/($channelCatalogId)/migrate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all list names
#
# GET /v2/user/lov/
# operationId: GetUserLovIndex
export def "user-lov GetUserLovIndex" [
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
export def "user-lov GetUserListOfValues" [
  listName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Language: list # Indicates that the client accepts the following languages.
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<items: table<codeIdentifier: string, intIdentifier: int, position: int, translationText: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/lov/($listName)")
  let extra_headers = {"Accept-Language": $Accept_Language, "If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get your marketplace channel catalog list
#
# GET /v2/user/marketplaces/channelcatalogs/
# operationId: GetMarketplaceChannelCatalogs
export def "user-marketplaces-channelcatalogs GetMarketplaceChannelCatalogs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceChannelCatalogs: table<apiSettingsStatus: string, beezUPChannelCatalogId: string, beezUPChannelId: string, beezUPMarketplaceName: any, beezUPStoreId: string, beezUPStoreName: string, enabled: bool, links: record, lovLinks: record, marketplaceAccountId: int, marketplaceBusinessCode: string, marketplaceIsoCountryCodeAlpha2: string, marketplaceMarketPlaceId: string, marketplaceMerchantIdentifiers: record, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/channelcatalogs/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Fetch the publication history for an account, sorted by descending start date
#
# GET /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/history
# operationId: GetPublications
export def "user-marketplaces-channelcatalogs-publications-history GetPublications" [
  marketplaceTechnicalCode: string
  accountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --channelCatalogId: string # Channel Catalog Id by which to filter (optional) (format: guid)
  --count: int # Amount of entries to fetch (optional, default set to 10) (format: int32, default: 10)
  --publicationTypes: list # Publication types by which to filter (optional)
]: nothing -> record<links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, publications: table<feeds: list, publicationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "channelCatalogId" $channelCatalogId "scalar") (serialize-qp "count" $count "scalar") (serialize-qp "publicationTypes" $publicationTypes "csv")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/channelcatalogs/publications/($marketplaceTechnicalCode)/($accountId)/history" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [PREVIEW] Launch a publication of the catalog to the marketplace
#
# POST /v2/user/marketplaces/channelcatalogs/publications/{marketplaceTechnicalCode}/{accountId}/publish
# operationId: PublishCatalogToMarketplace
export def "user-marketplaces-channelcatalogs-publications-publish PublishCatalogToMarketplace" [
  marketplaceTechnicalCode: string
  accountId: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  feedType: string@feedType-completer # The Feed Type (e.g. Offers)
  publicationStrategyKind: string@publicationStrategyKind-completer # Define the publication strategy kind, for that you have 2 choices  * Delta - This is the recommanded publication strategy kind, this strategy will push to the marketplace only the difference between your catalog and the previous published feeds done by BeezUP.  * Full - If you want to force the publication of all your catalog feeds to the marketplace.        !WARNING! Depending to the marketplace this operation will purge the existing offers on the marketplace that are not in the catalog or unknown from the publication feed referential.  (default: Delta)
  --withUnpublish: oneof<nothing, bool> # In full publication strategy kind, for some marktetplace, you can ask to unpublish or not your existing feeds on the markeptlace absent from your exported catalog.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/channelcatalogs/publications/($marketplaceTechnicalCode)/($accountId)/publish")
  let body = {feedType: $feedType, publicationStrategyKind: $publicationStrategyKind, withUnpublish: $withUnpublish} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the marketplace properties for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/properties
# operationId: GetChannelCatalogMarketplaceProperties
export def "user-marketplaces-channelcatalogs-properties GetChannelCatalogMarketplaceProperties" [
  channelCatalogId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --redirectionPageUrl: string # format: uri
  --Accept-Language: list # Indicates that the client accepts the following languages.
]: nothing -> record<info: record<errors: list<record>, informations: list<record>, successes: list<record>, warnings: list<record>>, links: record<externalConfigurationPage: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, settings: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, propertyGroups: table<name: string, position: int, properties: list>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "redirectionPageUrl" $redirectionPageUrl "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/channelcatalogs/($channelCatalogId)/properties" $qp)
  let extra_headers = {"Accept-Language": $Accept_Language} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the marketplace settings for a channel catalog
#
# GET /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# operationId: GetChannelCatalogMarketplaceSettings
export def "user-marketplaces-channelcatalogs-settings GetChannelCatalogMarketplaceSettings" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/marketplaces/channelcatalogs/($channelCatalogId)/settings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Save new marketplace settings for a channel catalog
#
# POST /v2/user/marketplaces/channelcatalogs/{channelCatalogId}/settings
# operationId: SetChannelCatalogMarketplaceSettings
# --settings item shape: {discriminatorType: "channelCatalogMarketplaceStringSetting"|"channelCatalogMarketplaceIntegerSetting"|"channelCatalogMarketplaceBooleanSetting"|"channelCatalogMarketplaceNumberSetting", name: string}
export def "user-marketplaces-channelcatalogs-settings SetChannelCatalogMarketplaceSettings" [
  channelCatalogId: string
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
  let full_url = (build-url $base $"/v2/user/marketplaces/channelcatalogs/($channelCatalogId)/settings")
  let body = {settings: $settings} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Get all actions you can do on the order API
#
# GET /v2/user/marketplaces/orders/
# DEPRECATED
# operationId: GetOrderIndex
@deprecated
export def "user-marketplaces-orders GetOrderIndex" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<links: record<autoTransitions: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, exportations: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, lightOrders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, orders: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, lovLinks: record<orderChangeBusinessOperationType: record<href: string, method: string>, orderProperty: record<href: string, method: string>, orderPropertyPosted: record<href: string, method: string>, orderState: record<href: string, method: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get list of configured automatic Order status transitions
#
# GET /v2/user/marketplaces/orders/automaticTransitions
# operationId: GetAutomaticTransitions
export def "user-marketplaces-orders-automatic-transitions GetAutomaticTransitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<automaticTransitionInfos: table<accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int, beezUPOrderStatus: string, businessOperationType: string, links: record, marketplaceBusinessCode: string>, links: record<configure: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/automaticTransitions" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Configure new or existing automatic Order status transition
#
# POST /v2/user/marketplaces/orders/automaticTransitions
# operationId: ConfigureAutomaticTransitions
# --automaticTransitions item shape: {accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int}
export def "user-marketplaces-orders-automatic-transitions ConfigureAutomaticTransitions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  automaticTransitions: list # item shape: {accountId: int, enabled: bool, marketplaceTechnicalCode: string, orderStatusTransitionId: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/automaticTransitions")
  let body = {automaticTransitions: $automaticTransitions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Send a batch of operations to change your marketplace Order information: accept, ship, etc.  (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/changeOrders/{changeOrderType}
# DEPRECATED
# operationId: ChangeOrderList
# --changeOrders item shape: {changeOrderRequest?: record, order: any}
@deprecated
export def "user-marketplaces-orders-batches-change-orders ChangeOrderList" [
  changeOrderType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  changeOrders: list # The change order operations — item shape: {changeOrderRequest?: record, order: any}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/batches/changeOrders/($changeOrderType)" $qp)
  let body = {changeOrders: $changeOrders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Send a batch of operations to clear an Order's merchant information (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/clearMerchantOrderInfos
# DEPRECATED
# operationId: ClearMerchantOrderInfoList
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string}
@deprecated
export def "user-marketplaces-orders-batches-clear-merchant-order-infos ClearMerchantOrderInfoList" [
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
  let body = {orders: $orders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Send a batch of operations to set an Order's merchant information  (max 100 items per call)
#
# POST /v2/user/marketplaces/orders/batches/setMerchantOrderInfos
# DEPRECATED
# operationId: SetMerchantOrderInfoList
# --orders item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
@deprecated
export def "user-marketplaces-orders-batches-set-merchant-order-infos SetMerchantOrderInfoList" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  order_MerchantECommerceSoftwareName: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_MerchantECommerceSoftwareVersion: string # The e-commece software version of the merchant (e.g. 123.0.1)
  orders: list # e.g. [{accountId: 1234, beezUPOrderId: 8D47FF1427A26B064ca98e95f644361ada5a5be0bbb3b53, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX1234}, {accountId: 5678, beezUPOrderId: 8D47FF149F213D055f26e3c413e4c9ba5c5cfda460547a4, marketplaceTechnicalCode: Amazon, order_MerchantOrderId: BX5678}, {accountId: 9876, beezUPOrderId: 8D47FF150217B60bdec05ab61c445d1a59e3da050b52823, marketplaceTechnicalCode: Ebay, order_MerchantOrderId: BX9876}] — item shape: {accountId: int, beezUPOrderId: string, marketplaceTechnicalCode: string, order_MerchantOrderId: string}
]: any -> record<operations: table<errors: list, order: record, status: int, success: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/batches/setMerchantOrderInfos")
  let body = {order_MerchantECommerceSoftwareName: $order_MerchantECommerceSoftwareName, order_MerchantECommerceSoftwareVersion: $order_MerchantECommerceSoftwareVersion, orders: $orders} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a paginated list of Order report exportations
#
# GET /v2/user/marketplaces/orders/exportations
# operationId: GetOrderExportations
export def "user-marketplaces-orders-exportations GetOrderExportations" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # The page number you want to get (format: int32, e.g. 1)
  --pageSize: int # The entry count you want to get (format: int32, e.g. 25)
  --storeId: string # The store identifier to regroup the order exportations (format: guid)
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<exportations: table<abortionUtcDate: string, beginUtcDate: string, blobNameUri: string, endUtcDate: string, enqueuedUtcDate: string, errorMessage: string, executionUUID: string, expirationUtcDate: string, failureUtcDate: string, ipAddress: string, jsonCriteria: string, lastUpdateUtcDate: string, orderCount: int, processingStatus: string, remainingOrderCount: int, resumedUtcDate: string, sourceType: string, sourceUserId: string, sourceUserName: string, suspendedUtcDate: string, timeoutDuration: string, warningMessage: string>, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/exportations" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Request a new Order report exportation to be generated
#
# POST /v2/user/marketplaces/orders/exportations
# operationId: ExportOrders
# --orderListRequestWithoutPagination shape: {accountIds?: list, beezUPOrderStatuses?: list, beginPeriodUtcDate: string, dateSearchType?: "Modification"|"Purchase"|"MarketPlaceModification", endPeriodUtcDate: string, invoiceAvailabilityType?: string, marketplaceBusinessCodes?: list, marketplaceOrderIds?: list, marketplaceTechnicalCodes?: list, orderMerchantInfoSynchronizationStatus?: string, order_Buyer_Name?: string, order_MerchantOrderIds?: list, storeIds?: list}
export def "user-marketplaces-orders-exportations ExportOrders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --format: string@format-completer-1 # The type of the file to export (default: csv, e.g. csv)
  orderListRequestWithoutPagination: record # shape: {accountIds?: list, beezUPOrderStatuses?: list, beginPeriodUtcDate: string, dateSearchType?: "Modification"|"Purchase"|"MarketPlaceModification", endPeriodUtcDate: string, invoiceAvailabilityType?: string, marketplaceBusinessCodes?: list, marketplaceOrderIds?: list, marketplaceTechnicalCodes?: list, orderMerchantInfoSynchronizationStatus?: string, order_Buyer_Name?: string, order_MerchantOrderIds?: list, storeIds?: list}
  storeId: string # The store identifier (format: guid, e.g. 64f43358-63a1-47f7-97ec-0301fc39956b)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/exportations")
  let body = {format: $format, orderListRequestWithoutPagination: $orderListRequestWithoutPagination, storeId: $storeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Send harvest request to all your marketplaces
#
# POST /v2/user/marketplaces/orders/harvest
# DEPRECATED
# operationId: HarvestAll
@deprecated
export def "user-marketplaces-orders-harvest HarvestAll" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/harvest" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate an Order Invoice batch
#
# POST /v2/user/marketplaces/orders/invoices/generate
# operationId: GenerateBatchOrderInvoice
export def "user-marketplaces-orders-invoices-generate GenerateBatchOrderInvoice" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --body: record
]: any -> table<accountId: int, beezUPOrderUUID: string, invoiceLocation: string, invoiceSequenceNumber: int, marketplaceTechnicalCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/generate" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the PDF version of the invoice
#
# POST /v2/user/marketplaces/orders/invoices/getPdfInvoice
# operationId: GetOrderInvoicePdf
export def "user-marketplaces-orders-invoices-get-pdf-invoice GetOrderInvoicePdf" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  orderInvoiceUri: string # order invoice url (e.g. http://www.mydomain.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/getPdfInvoice")
  let body = {orderInvoiceUri: $orderInvoiceUri} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/pdf"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Order Invoice design settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/design
# operationId: GetOrderInvoiceDesignSettings
export def "user-marketplaces-orders-invoices-settings-design GetOrderInvoiceDesignSettings" [
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
export def "user-marketplaces-orders-invoices-settings-design SaveOrderInvoiceDesignSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --footerContentHtml: string # Footer Content HTML
  --headerContentHtml: string # Header Content HTML
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/design")
  let body = {footerContentHtml: $footerContentHtml, headerContentHtml: $headerContentHtml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a preview an Order Invoice using custom design settings
#
# POST /v2/user/marketplaces/orders/invoices/settings/design/preview
# operationId: GetOrderInvoiceDesignSettingsPreview
export def "user-marketplaces-orders-invoices-settings-design-preview GetOrderInvoiceDesignSettingsPreview" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --footerContentHtml: string # Footer Content HTML
  --headerContentHtml: string # Header Content HTML
]: any -> record<invoiceHtmlContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/design/preview")
  let body = {footerContentHtml: $footerContentHtml, headerContentHtml: $headerContentHtml} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Order Invoice general settings
#
# GET /v2/user/marketplaces/orders/invoices/settings/general
# operationId: GetOrderInvoiceGeneralSettings
export def "user-marketplaces-orders-invoices-settings-general GetOrderInvoiceGeneralSettings" [
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
export def "user-marketplaces-orders-invoices-settings-general SaveOrderInvoiceGeneralSettings" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  cultureName: string # If the error is translated, the culture name will be indicated (e.g. en)
  invoicePrefix: string # Invoice Prefix. Can contain 1 to 50 characters, with alphanumeric characters in lowercase uppercase and #, _, - (e.g. TOTO)
  invoiceStartingSequenceNumber: int # Invoice Sequence Number (e.g. 879)
  productVATPercent: float # Product VAT in percent (e.g. 4.0)
  shippingVATPercent: float # Shipping cost VAT in percent (e.g. 8.0)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/invoices/settings/general")
  let body = {cultureName: $cultureName, invoicePrefix: $invoicePrefix, invoiceStartingSequenceNumber: $invoiceStartingSequenceNumber, productVATPercent: $productVATPercent, shippingVATPercent: $shippingVATPercent} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Generate an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/generate
# operationId: GenerateOrderInvoice
export def "user-marketplaces-orders-invoices-generate GenerateOrderInvoice" [
  marketplaceTechnicalCode: string
  accountId: string
  beezUPOrderUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --invoiceSequenceNumber: int # Invoice Sequence Number (e.g. 879)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/invoices/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderUUID)/generate" $qp)
  let body = {invoiceSequenceNumber: $invoiceSequenceNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# View a preview an Order Invoice
#
# POST /v2/user/marketplaces/orders/invoices/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderUUID}/preview
# operationId: GetOrderInvoicePreview
export def "user-marketplaces-orders-invoices-preview GetOrderInvoicePreview" [
  marketplaceTechnicalCode: string
  accountId: string
  beezUPOrderUUID: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: string # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --invoiceSequenceNumber: int # Invoice Sequence Number (e.g. 879)
]: any -> record<invoiceHtmlContent: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/invoices/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderUUID)/preview")
  let body = {invoiceSequenceNumber: $invoiceSequenceNumber} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Get a paginated list of all Orders with all Order and Order Item(s) properties
#
# POST /v2/user/marketplaces/orders/list/full
# DEPRECATED
# operationId: GetOrderListFull
@deprecated
export def "user-marketplaces-orders-list-full GetOrderListFull" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept-Encoding: list # Allows the client to indicate wether it accepts a compressed encoding to reduce traffic size
  --accountIds: list # Account Id list (e.g. [12345])
  --beezUPOrderStatuses: list # e.g. [InProgress]
  beginPeriodUtcDate: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period.  (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --dateSearchType: string@dateSearchType-completer # Indicates on which date you want to make the filter (default: Modification)
  endPeriodUtcDate: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date.  (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoiceAvailabilityType: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplaceBusinessCodes: list # e.g. [PRICEMINISTER]
  --marketplaceOrderIds: list # e.g. [AmazonOrderId1234]
  --marketplaceTechnicalCodes: list # e.g. [PriceMinister]
  --orderMerchantInfoSynchronizationStatus: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-Buyer-Name: string # Buyer full name (e.g. Monroe)
  --order-MerchantOrderIds: list # Merchant order id list (e.g. [MyOrderId1234])
  --storeIds: list # Store Id list
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: list, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: list>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/list/full")
  let body = {accountIds: $accountIds, beezUPOrderStatuses: $beezUPOrderStatuses, beginPeriodUtcDate: $beginPeriodUtcDate, dateSearchType: $dateSearchType, endPeriodUtcDate: $endPeriodUtcDate, invoiceAvailabilityType: $invoiceAvailabilityType, marketplaceBusinessCodes: $marketplaceBusinessCodes, marketplaceOrderIds: $marketplaceOrderIds, marketplaceTechnicalCodes: $marketplaceTechnicalCodes, orderMerchantInfoSynchronizationStatus: $orderMerchantInfoSynchronizationStatus, order_Buyer_Name: $order_Buyer_Name, order_MerchantOrderIds: $order_MerchantOrderIds, storeIds: $storeIds, pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept-Encoding": $Accept_Encoding} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Get a paginated list of all Orders without details
#
# POST /v2/user/marketplaces/orders/list/light
# DEPRECATED
# operationId: GetOrderListLight
@deprecated
export def "user-marketplaces-orders-list-light GetOrderListLight" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountIds: list # Account Id list (e.g. [12345])
  --beezUPOrderStatuses: list # e.g. [InProgress]
  beginPeriodUtcDate: string # The begin period you want to make the search. \ The period MUST not be greater than 62 days. The begin period MUST be lower than the end period.  (format: date-time, e.g. 2017-03-01T13:10:01Z)
  --dateSearchType: string@dateSearchType-completer # Indicates on which date you want to make the filter (default: Modification)
  endPeriodUtcDate: string # The end period of you search. \ The period MUST not be greater than 62 days. \ The end period MUST be greater than the begin period. The end period MUST be lower to the current date.  (format: date-time, e.g. 2017-04-01T13:10:01Z)
  --invoiceAvailabilityType: string # Indicates on which invoice availability to filter (e.g. All)
  --marketplaceBusinessCodes: list # e.g. [PRICEMINISTER]
  --marketplaceOrderIds: list # e.g. [AmazonOrderId1234]
  --marketplaceTechnicalCodes: list # e.g. [PriceMinister]
  --orderMerchantInfoSynchronizationStatus: string # Indicates on which order merchant info synchronization status to filter (e.g. All)
  --order-Buyer-Name: string # Buyer full name (e.g. Monroe)
  --order-MerchantOrderIds: list # Merchant order id list (e.g. [MyOrderId1234])
  --storeIds: list # Store Id list
  pageNumber: int # Indicates the page number (format: int32, default: 1, e.g. 1)
  pageSize: int # Indicate the order count per page (format: int32, default: 100, e.g. 100)
]: any -> record<links: record<clearMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, export: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfos: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, status: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, orders: table<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool>, paginationResult: record<entryCount: int, links: record<first: record, last: record, next: record, previous: record>, pageCount: int, totalEntryCount: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/user/marketplaces/orders/list/light")
  let body = {accountIds: $accountIds, beezUPOrderStatuses: $beezUPOrderStatuses, beginPeriodUtcDate: $beginPeriodUtcDate, dateSearchType: $dateSearchType, endPeriodUtcDate: $endPeriodUtcDate, invoiceAvailabilityType: $invoiceAvailabilityType, marketplaceBusinessCodes: $marketplaceBusinessCodes, marketplaceOrderIds: $marketplaceOrderIds, marketplaceTechnicalCodes: $marketplaceTechnicalCodes, orderMerchantInfoSynchronizationStatus: $orderMerchantInfoSynchronizationStatus, order_Buyer_Name: $order_Buyer_Name, order_MerchantOrderIds: $order_MerchantOrderIds, storeIds: $storeIds, pageNumber: $pageNumber, pageSize: $pageSize} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Get current synchronization status between your marketplaces and BeezUP accounts
#
# GET /v2/user/marketplaces/orders/status
# DEPRECATED
# operationId: GetMarketplaceAccountsSynchronization
@deprecated
export def "user-marketplaces-orders-status GetMarketplaceAccountsSynchronization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --storeId: string # The StoreId to filter by (format: guid, e.g. 04730364-9826-4ff3-92e4-51fccd02bf10)
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountSynchronizations: table<accountId: int, completedHarvestSynchroUtcDate: string, marketplaceBusinessCode: string, marketplaceTechnicalCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "storeId" $storeId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/v2/user/marketplaces/orders/status" $qp)
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the subscription list
#
# GET /v2/user/marketplaces/orders/subscriptions/
# operationId: GetSubscriptionList
export def "user-marketplaces-orders-subscriptions GetSubscriptionList" [
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
export def "user-marketplaces-orders-subscriptions DeleteSubscription" [
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a subscription to the orders
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: GetSubscription
export def "user-marketplaces-orders-subscriptions GetSubscription" [
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}
# operationId: CreateSubscription
export def "user-marketplaces-orders-subscriptions CreateSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  merchantApplicationName: string # The name of your application (e.g. MyApp)
  merchantApplicationVersion: string # The version of your application (default: 1.0, e.g. 1.0)
  --merchantEmailAlert: string # The email (format: email, e.g. paulsimon@mysupercompany.com)
  name: string # The subscription name you want to use (e.g. MySubscriptionName)
  targetUrl: string # The URL <a href="https://en.wikipedia.org/wiki/URL">https://en.wikipedia.org/wiki/URL</a> (e.g. http://www.mydomain.com)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)")
  let body = {merchantApplicationName: $merchantApplicationName, merchantApplicationVersion: $merchantApplicationVersion, merchantEmailAlert: $merchantEmailAlert, name: $name, targetUrl: $targetUrl} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Activate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/activate
# operationId: ActivateSubscription
export def "user-marketplaces-orders-subscriptions-activate ActivateSubscription" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --recoverBeginPeriodOrderLastModificationUtcDate: string # If set, the date must be in the past the subscription will recover existing orders using the begin period order last modification date. If not set then you will receive new/updated orders in real-time. (format: date-time)
  --recoverEndPeriodOrderLastModificationUtcDate: string # If end period set, first the date must be in the past, the subscription will recover existing orders using the begin and the end period order last modification date.  If end period is not set and the begin period is set, then you will recover existing orders from the past using the begin period last modification date and after than you will continue to receive new/updated orders in real-time. If begin/end period are not set then you will receive new/updated orders in real-time. REMARK: The begin period is required if the end period is fulfilled. REMARK: If the end period is order last modification date is indicated then once we have push all orders to your target url the subscription will be desactivated. (format: date-time)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)/activate")
  let body = {recoverBeginPeriodOrderLastModificationUtcDate: $recoverBeginPeriodOrderLastModificationUtcDate, recoverEndPeriodOrderLastModificationUtcDate: $recoverEndPeriodOrderLastModificationUtcDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deactivate a subscription to the orders
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/deactivate
# operationId: DeactivateSubscription
export def "user-marketplaces-orders-subscriptions-deactivate DeactivateSubscription" [
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)/deactivate")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the push reporting related to this subscription
#
# GET /v2/user/marketplaces/orders/subscriptions/{id}/reporting
# operationId: GetSubscriptionPushReporting
export def "user-marketplaces-orders-subscriptions-reporting GetSubscriptionPushReporting" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pageNumber: int # format: PageNumber
  --pageSize: int # format: PageSize
]: nothing -> table<duration: string, errorMessage: record<errors: list>, eventId: string, httpStatus: int, lastOrderModificationUtcDate: string, maxRetryCount: int, nextScheduledRetryUtcDate: string, orderCount: int, requestUri: string, responseUri: string, retryCount: int, subscriptionId: string, succeed: bool> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNumber" $pageNumber "scalar") (serialize-qp "pageSize" $pageSize "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)/reporting" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Force retry push orders immediatly
#
# POST /v2/user/marketplaces/orders/subscriptions/{id}/retry
# operationId: RetryPushOrders
export def "user-marketplaces-orders-subscriptions-retry RetryPushOrders" [
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/subscriptions/($id)/retry")
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
export def "user-marketplaces-orders GetOrder" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<accountId: int, beezUPOrderId: string, beezUPOrderUrl: string, etag: string, links: record<self: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, clearMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, harvest: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, history: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>, setMerchantInfo: record<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool>>, marketplaceBusinessCode: string, marketplaceTechnicalCode: string, order_Buyer_Name: string, order_CurrencyCode: string, order_Invoice_Number: string, order_Invoice_Uri: string, order_LastModificationUtcDate: string, order_MarketplaceLastModificationUtcDate: string, order_MarketplaceOrderId: string, order_MerchantECommerceSoftwareName: string, order_MerchantECommerceSoftwareVersion: string, order_MerchantOrderId: string, order_PurchaseUtcDate: string, order_Status_BeezUPOrderStatus: string, order_Status_MarketplaceOrderStatus: string, order_TotalPrice: float, processing: bool, orderItems: table<beezUPOrderItemId: string, orderItem_BeezUPStoreId: string, orderItem_Condition: string, orderItem_ImageUrl: string, orderItem_ItemPrice: float, orderItem_ItemTax: float, orderItem_MarketPlaceProductId: string, orderItem_MarketplaceImageUri: string, orderItem_MarketplaceProductUri: string, orderItem_MerchantImportedProductId: string, orderItem_MerchantImportedProductIdColumnName: string, orderItem_MerchantImportedProductUrl: string, orderItem_MerchantProductId: string, orderItem_MerchantProductIdColumnName: string, orderItem_OrderItemType: string, orderItem_Quantity: float, orderItem_Shipping_Price: float, orderItem_Title: string, orderItem_TotalPrice: float, orderItem_gtin: string>, order_Buyer_AddressCity: string, order_Buyer_AddressCountryIsoCodeAlpha2: string, order_Buyer_AddressCountryName: string, order_Buyer_AddressLine1: string, order_Buyer_AddressLine2: string, order_Buyer_AddressLine3: string, order_Buyer_AddressPostalCode: string, order_Buyer_AddressStateOrRegion: string, order_Buyer_Civility: string, order_Buyer_CompanyName: string, order_Buyer_Email: string, order_Buyer_FirstName: string, order_Buyer_Identifier: string, order_Buyer_LastName: string, order_Buyer_MobilePhone: string, order_Buyer_Phone: string, order_Comment: string, order_FulfilledBy: string, order_IsBusiness: bool, order_IsPrime: bool, order_MarketPlaceChannel: string, order_OrderItemsSourceUri: string, order_OrderSourceUri: string, order_PayingUtcDate: string, order_PaymentMethod: string, order_Shipping_AddressCity: string, order_Shipping_AddressCountryIsoCodeAlpha2: string, order_Shipping_AddressCountryName: string, order_Shipping_AddressLine1: string, order_Shipping_AddressLine2: string, order_Shipping_AddressLine3: string, order_Shipping_AddressName: string, order_Shipping_AddressPostalCode: string, order_Shipping_AddressStateOrRegion: string, order_Shipping_Civility: string, order_Shipping_CompanyName: string, order_Shipping_EarliestShipUtcDate: string, order_Shipping_Email: string, order_Shipping_FirstName: string, order_Shipping_LastName: string, order_Shipping_LatestShipUtcDate: string, order_Shipping_Method: string, order_Shipping_MobilePhone: string, order_Shipping_Phone: string, order_Shipping_Price: float, order_Shipping_ShippingTax: float, order_TotalCommission: float, order_TotalTax: float, transitionLinks: table<allOptionalParamsProvided: bool, allRequiredParamsProvided: bool, description: string, docUrl: string, href: string, info: record, label: string, method: string, operationId: string, parameters: record, urlTemplated: bool, rel: string>> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] DEPRECATED - Get the meta information about the order (ETag, Last-Modified)
#
# HEAD /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}
# DEPRECATED
# operationId: HeadOrder
@deprecated
export def "user-marketplaces-orders HeadOrder" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "head" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Clear an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/clearMerchantOrderInfo
# DEPRECATED
# operationId: ClearMerchantOrderInfo
@deprecated
export def "user-marketplaces-orders-clear-merchant-order-info ClearMerchantOrderInfo" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/clearMerchantOrderInfo")
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
export def "user-marketplaces-orders-harvest HarvestOrder" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
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
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/harvest")
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
export def "user-marketplaces-orders-history GetOrderHistory" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --If-None-Match: string # ETag value to identify the last known version of requested resource.\ To avoid useless exchange, we recommend you to indicate the ETag you previously got from this operation.\ If the ETag value does not match the response will be 200 to give you a new content, otherwise the response will be: 304 Not Modified, without any content.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
]: nothing -> record<changeOrderReportings: table<changeOrderType: string, creationUtcDate: string, details: record, errorMessage: string, executionUUID: string, ipAddress: string, lastUpdateUtcDate: string, processingStatus: string, sourceType: string, sourceUserId: string, sourceUserName: string, testMode: bool>, harvestOrderReportings: table<beezUPForcedStatus: string, beezUPStatus: string, creationUtcDate: string, errorMessage: string, executionUUID: string, lastUpdateUtcDate: string, marketplaceStatus: string, processingStatus: string, warningMessage: string>, lastModificationUtcDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/history")
  let extra_headers = {"If-None-Match": $If_None_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# [DEPRECATED] Set an Order's merchant information
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/setMerchantOrderInfo
# DEPRECATED
# operationId: SetMerchantOrderInfo
@deprecated
export def "user-marketplaces-orders-set-merchant-order-info SetMerchantOrderInfo" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  order_MerchantECommerceSoftwareName: string # The e-commerce software name of the merchant (e.g. Prestashop)
  order_MerchantECommerceSoftwareVersion: string # The e-commece software version of the merchant (e.g. 123.0.1)
  order_MerchantOrderId: string # The order merchant identifier (e.g. MyOrderMerchantId)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/setMerchantOrderInfo")
  let body = {order_MerchantECommerceSoftwareName: $order_MerchantECommerceSoftwareName, order_MerchantECommerceSoftwareVersion: $order_MerchantECommerceSoftwareVersion, order_MerchantOrderId: $order_MerchantOrderId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED] Change your marketplace Order Information (accept, ship, etc.)
#
# POST /v2/user/marketplaces/orders/{marketplaceTechnicalCode}/{accountId}/{beezUPOrderId}/{changeOrderType}
# DEPRECATED
# operationId: ChangeOrder
@deprecated
export def "user-marketplaces-orders ChangeOrder" [
  marketplaceTechnicalCode: string
  accountId: int
  beezUPOrderId: string
  changeOrderType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --userName: string # Sometimes the user in the e-commerce application is not the same as user associated with the current subscription key. We recommend providing your application's user login.
  --testMode: oneof<nothing, bool> # If true, the operation will be not be sent to marketplace. But the validation will be taken in account. (default: false, e.g. false)
  --If-Match: string # ETag value to identify the last known version of requested resource.\ To ensure that you are making a change on the lastest version of the resource.\ For more details go to this link: http://tools.ietf.org/html/rfc7232#section-2.3
  --body: record
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "ocp-apim-subscription-key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "userName" $userName "scalar") (serialize-qp "testMode" $testMode "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/user/marketplaces/orders/($marketplaceTechnicalCode)/($accountId)/($beezUPOrderId)/($changeOrderType)" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
