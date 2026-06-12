# Auto-generated client for eBay Finances API vv1.15.0
# Source: https://api.apis.guru/v2/specs/apiz.ebay.com/sell-finances/v1.15.0/openapi.json
# Auth: --token flag or $env.EBAY_FINANCES_API_TOKEN

const BASE_URL = "https://apiz.ebay.com/sell/finances/v1"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o EBAY_FINANCES_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://apiz.ebay.com/sell/finances/v1"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "payout list" } } | get name | first)
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

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>This method is used to retrieve the details of one or more seller payouts. By using the <b>filter</b> query parameter, users can retrieve payouts processed within a specific date range, and/or they can retrieve payouts in a specific state.<br><br>There are also pagination and sort query parameters that allow users to control the payouts that are returned in the response.<br><br>If no payouts match the input criteria, an empty payload is returned.
#
# GET /payout
# operationId: getPayouts
export def "payout list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The three filter types that can be used here are discussed below. If none of these filters are used, all recent payouts in all states are returned:<ul><li><b>payoutDate</b>: search for payouts within a specific range of dates. The date format to use is <code>YYYY-MM-DDTHH:MM:SS.SSSZ</code>. Below is the proper syntax to use if filtering by a date range: <br><br><code>https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]</code><br><br>Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past.</li><li><b>lastAttemptedPayoutDate</b>: search for attempted payouts that failed within a specific range of dates. In order to use this filter, the <b>payoutStatus</b> filter must also be used and its value must be set to <code>RETRYABLE_FAILED</code>. The date format to use is <code>YYYY-MM-DDTHH:MM:SS.SSSZ</code>. The same syntax used for the <b>payoutDate</b> filter is also used for the <b>lastAttemptedPayoutDate</b> filter. <br><br>This filter is only applicable (and will return results) if one or more seller payouts have failed, but are retryable.</li> <li><b>payoutStatus</b>: search for payouts in a particular state. Only one payout state can be specified with this filter. The supported <b>payoutStatus</b> values are as follows:<ul><li><code>INITIATED</code>: search for payouts that have been initiated but not processed.</li><li><code>SUCCEEDED</code>: search for successful payouts.</li><li><code>RETRYABLE_FAILED</code>: search for payouts that failed, but ones which will be tried again. This value must be used if filtering by <b>lastAttemptedPayoutDate</b>. </li><li><code>TERMINAL_FAILED</code>: search for payouts that failed, and ones that will not be tried again.</li><li> <code>REVERSED</code>: search for payouts that were reversed. </li></ul>Below is the proper syntax to use if filtering by payout status: <br><br><code>https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutStatus:{SUCCEEDED}</code></ul><br>If both the <b>payoutDate</b> and <b>payoutStatus</b> filters are used, payouts must satisfy both criteria to be returned. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --limit: string # The number of payouts to return per page of the result set. Use this parameter in conjunction with the <b>offset</b> parameter to control the pagination of the output. <br><br> For example, if <b>offset</b> is set to <code>10</code> and <b>limit</b> is set to <code>10</code>, the method retrieves payouts 11 thru 20 from the result set. <br><br> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first payout in the results set has an offset value of <code>0</code>. </span> <br><br> <b>Maximum:</b> <code>200</code> <br> <b>Default:</b> <code>20</code>
  --offset: string # This integer value indicates the actual position that the first payout returned on the current page has in the results set. So, if you wanted to view the 11th payout of the result set, you would set the <strong>offset</strong> value in the request to <code>10</code>. <br><br>In the request, you can use the <b>offset</b> parameter in conjunction with the <b>limit</b> parameter to control the pagination of the output. For example, if <b>offset</b> is set to <code>30</code> and <b>limit</b> is set to <code>10</code>, the method retrieves payouts 31 thru 40 from the resulting collection of payouts. <br><br> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first payout in the results set has an offset value of <code>0</code>.</span><br><br><b>Default:</b> <code>0</code> (zero)
  --qp-sort: string # By default, payouts or failed payouts that match the input criteria are sorted in descending order according to the payout date/last attempted payout date (i.e., most recent payouts returned first).<br><br>To view payouts in ascending order instead (i.e., oldest payouts/attempted payouts first,) you would include the <b>sort</b> query parameter, and then set the value of its <b>field</b> parameter to <code>payoutDate</code> or <code>lastAttemptedPayoutDate</code> (if searching for failed, retryable payouts). Below is the proper syntax to use if filtering by a payout date range in ascending order:<br><br><code>https://apiz.ebay.com/sell/finances/v1/payout?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]&sort=payoutDate</code><br><br>Payouts can only be sorted according to payout date, and can not be sorted by payout status. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:SortField
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<href: string, limit: int, next: string, offset: int, payouts: table<amount: record, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record, totalFee: record, transactionCount: int>, prev: string, total: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payout" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>This method retrieves details on a specific seller payout. The unique identfier of the payout is passed in as a path parameter at the end of the call URI. <br><br>The <b>getPayouts</b> method can be used to retrieve the unique identifier of a payout, or the user can check Seller Hub.
#
# GET /payout/{payout_Id}
# operationId: getPayout
export def "payout get" [
  payout_Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, bankReference: string, lastAttemptedPayoutDate: string, payoutDate: string, payoutId: string, payoutInstrument: record<accountLastFourDigits: string, instrumentType: string, nickname: string>, payoutMemo: string, payoutStatus: string, payoutStatusDescription: string, totalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFee: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transactionCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/payout/($payout_Id)")
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>This method is used to retrieve cumulative values for payouts in a particular state, or all states. The metadata in the response includes total payouts, the total number of monetary transactions (sales, refunds, credits) associated with those payouts, and the total dollar value of all payouts.<br><br>If the <b>filter</b> query parameter is used to filter by payout status, only one payout status value may be used. If the <b>filter</b> query parameter is not used to filter by a specific payout status, cumulative values for payouts in all states are returned.<br><br>The user can also use the <b>filter</b> query parameter to specify a date range, and then only payouts that were processed within that date range are considered.
#
# GET /payout_summary
# operationId: getPayoutSummary
export def "payout-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # The two filter types that can be used here are discussed below. One or both of these filter types can be used. If none of these filters are used, the data returned in the response will reflect payouts, in all states, processed within the last 90 days. <ul><li><b>payoutDate</b>: consider payouts processed within a specific range of dates. The date format to use is <code>YYYY-MM-DDTHH:MM:SS.SSSZ</code>. Below is the proper syntax to use if filtering by a date range: <br><br><code>https://apiz.ebay.com/sell/finances/v1/payout_summary?filter=payoutDate:[2018-12-17T00:00:01.000Z..2018-12-24T00:00:01.000Z]</code><br><br>Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past.</li> <li><b>payoutStatus</b>: consider only the payouts in a particular state. Only one payout state can be specified with this filter. The supported <b>payoutStatus</b> values are as follows:<ul><li><code>INITIATED</code>: search for payouts that have been initiated but not processed.</li><li><code>SUCCEEDED</code>: consider only successful payouts.</li><li><code>RETRYABLE_FAILED</code>: consider only payouts that failed, but ones which will be tried again.</li><li><code>TERMINAL_FAILED</code>: consider only payouts that failed, and ones that will not be tried again.</li><li> <code>REVERSED</code>: consider only payouts that were reversed. </li></ul>Below is the proper syntax to use if filtering by payout status: <br><br><code>https://apiz.ebay.com/sell/finances/v1/payout_summary?filter=payoutStatus:{SUCCEEDED}</code></ul><br>If both the <b>payoutDate</b> and <b>payoutStatus</b> filters are used, only the payouts that satisfy both criteria are considered in the results. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<amount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, payoutCount: int, transactionCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/payout_summary" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>This method retrieves all pending funds that have not yet been distibuted through a seller payout.<br><br>There are no input parameters for this method. The response payload includes available funds, funds being processed, funds on hold, and also an aggregate count of all three of these categories.<br><br>If there are no funds that are pending, on hold, or being processed for the seller's account, no response payload is returned, and an http status code of <code>204 - No Content</code> is returned instead.
#
# GET /seller_funds_summary
# operationId: getSellerFundsSummary
export def "seller-funds-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<availableFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, fundsOnHold: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, processingFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, totalFunds: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/seller_funds_summary")
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>The <b>getTransactions</b> method allows a seller to retrieve information about one or more of their monetary transactions.<br><br><span class="tablenote"><b>Note:</b> For a complete list of transaction types, refer to <a href="/api-docs/sell/finances/types/pay:TransactionTypeEnum " target="_blank ">TransactionTypeEnum</a>.</span><br>Numerous input filters are available which can be used individualy or combined to refine the data that are returned. For example:<ul><li><code>SALE</code> transactions for August 15, 2022;</li><li><code>RETURN</code> transactions for the month of January, 2021;</li><li>Transactions currently in a <code>transactionStatus</code> equal to <code>FUNDS_ON_HOLD</code>.</li></ul>Refer to the <a href="#uri.filter ">filter</a> field for additional information about each filter and its use.<br><br>Pagination and sort query parameters are also provided that allow users to further control how monetary transactions are displayed in the response.<br><br>If no monetary transactions match the input criteria, an http status code of <em>204 No Content</em> is returned with no response payload.
#
# GET /transaction
# operationId: getTransactions
export def "transaction get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Numerous filters are available for the <strong>getTransactions</strong> method, and these filters are discussed below. One or more of these filter types can be used. If none of these filters are used, all monetary transactions from the last 90 days are returned:<ul><li><b>transactionDate</b>: search for monetary transactions that occurred within a specific range of dates.<br><br><span class="tablenote"><strong>Note:</strong> All dates must be input using UTC format (<code>YYYY-MM-DDTHH:MM:SS.SSSZ</code>) and should be adjusted accordingly for the local timezone of the user.</span><br><br>Below is the proper syntax to use if filtering by a date range: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionDate:[2018-10-23T00:00:01.000Z..2018-11-09T00:00:01.000Z]</code><br><br>Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past.</li>  <li><b>transactionType</b>: search for a specific type of monetary transaction. The supported <b>transactionType</b> values are as follows:<ul><li><code>SALE</code>: a sales order.</li><li> <code>REFUND</code>: a refund to the buyer after an order cancellation or return.</li><li><code>CREDIT</code>: a credit issued by eBay to the seller's account.</li><li><code>DISPUTE</code>: a monetary transaction associated with a payment dispute between buyer and seller.</li><li><code>NON_SALE_CHARGE</code>: a monetary transaction involving a seller transferring money to eBay for the balance of a charge for NON_SALE_CHARGE transactions (transactions that contain non-transactional seller fees). These can include a one-time payment, monthly/yearly subscription fees charged monthly, NRC charges, and fee credits.</li><li><code>SHIPPING_LABEL</code>: a monetary transaction where eBay is billing the seller for an eBay shipping label. Note that the shipping label functionality will initially only be available to a select number of sellers.</li><li><code>TRANSFER</code>: A transfer is a monetary transaction where eBay is billing the seller for reimbursement of a charge. An example of a transfer is a seller reimbursing eBay for a buyer refund.</li><li><code>ADJUSTMENT</code>: An adjustment is a monetary transaction where eBay is crediting or debiting the seller's account.</li><li><code>WITHDRAWAL</code>: A withdrawal is a monetary transaction where the seller requests an on-demand payout from eBay.<br><br><span class="tablenote"><b>Note:</b> On-demand payout is not available for sellers who are already on a <b>daily</b> payout schedule. In order to initiate an on-demand payout, a seller must be on a <b>weekly</b>, <b>bi-weekly</b>, or <b>monthly</b> payout schedule.</span></li><li><code>LOAN_REPAYMENT</code>: A monetary transaction related to the repayment of an outstanding loan balance for approved participants enrolled in the <a href="https://pages.ebay.com/sellercapital/ " target="_blank ">eBay Seller Capital financing program</a>.<br><br><span class="tablenote"><b>Note:</b> eBay Seller Capital financing is only available in select marketplaces. Refer to <a href="/api-docs/sell/finances/overview.html#loans " target="_blank ">Marketplace availability for eBay Seller Capital funding program</a> for current marketplace eligibility.</span></li></ul>Below is the proper syntax to use if filtering by a monetary transaction type: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionType:{SALE}</code></li><li><b>transactionStatus</b>: this filter type is only applicable for sales orders, and allows the user to filter seller payouts in a particular state.  The supported <b>transactionStatus</b> values are as follows:<ul><li><code>PAYOUT</code>: this indicates that the proceeds from the corresponding sales order has been paid out to the seller's account.</li><li><code>FUNDS_PROCESSING</code>: this indicates that the funds for the corresponding monetary transaction are currently being processed.</li><li><code>FUNDS_AVAILABLE_FOR_PAYOUT</code>: this indicates that the proceeds from the corresponding sales order are available for a seller payout, but processing has not yet begun.</li><li><code>FUNDS_ON_HOLD</code>: this indicates that the proceeds from the corresponding sales order are currently being held by eBay, and are not yet available for a seller payout.</li><li><code>COMPLETED</code>: this indicates that the funds for the corresponding <code>TRANSFER</code> monetary transaction have transferred and the transaction has completed.</li><li><code>FAILED</code>: this indicates the process has failed for the corresponding <code>TRANSFER</code> monetary transaction. </li></ul>Below is the proper syntax to use if filtering by transaction status: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionStatus:{PAYOUT}</code></li><li><b>buyerUsername</b>: the eBay user ID of the buyer involved in the monetary transaction. Only monetary transactions involving this buyer are returned. Below is the proper syntax to use if filtering by a specific eBay buyer: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=buyerUsername:{buyer1234}</code> </li><li><b>salesRecordReference</b>: the unique Selling Manager identifier of the order involved in the monetary transaction. Only monetary transactions involving this Selling Manager Sales Record ID are returned. Below is the proper syntax to use if filtering by a specific Selling Manager Sales Record ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=salesRecordReference:{123}</code><br><br><span class="tablenote"><strong>Note:</strong> For all orders originating after February 1, 2020, a value of <code>0</code> will be returned in the <b>salesRecordReference</b> field. So, this filter will only be useful to retrieve orders than occurred before this date. </span></li><li><b>payoutId</b>: the unique identifier of a seller payout. This value is auto-generated by eBay once the seller payout is set to be processed. Only monetary transactions involving this Payout ID are returned. Below is the proper syntax to use if filtering by a specific Payout ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=payoutId:{5********8}</code>  </li><li><b>transactionId</b>: the unique identifier of a monetary transaction. For a sales order, the <b>orderId</b> filter should be used instead. Only the monetary transaction defined by the identifier is returned.<br><br><span class="tablenote"><strong>Note:</strong> This filter cannot be used alone; the <b>transactionType</b> must also be specified when filtering by transaction ID.</span><br><br>Below is the proper syntax to use if filtering by a specific transaction ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=transactionId:{0*-0***0-3***3}&filter=transactionType:{SALE}</code> </li><li><b>orderId</b>: the unique identifier of a sales order. Only monetary transaction(s) associated with this <b>orderId</b> value are returned.<br><br>For any other monetary transaction, the <b>transactionId</b> filter should be used instead.<br><br>Below is the proper syntax to use if filtering by a specific order ID:<br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction?filter=orderId:{0*-0***0-3***3}</code> </li></ul> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --limit: string # The number of monetary transactions to return per page of the result set. Use this parameter in conjunction with the <b>offset</b> parameter to control the pagination of the output. <br><br> For example, if <b>offset</b> is set to <code>10</code> and <b>limit</b> is set to <code>10</code>, the method retrieves monetary transactions 11 thru 20 from the result set. <br><br> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span> <br><br> <b>Maximum:</b><code> 1000</code> <br> <b>Default:</b><code> 20</code>
  --offset: string # This integer value indicates the actual position that the first monetary transaction returned on the current page has in the results set. So, if you wanted to view the 11th monetary transaction of the result set, you would set the <strong>offset</strong> value in the request to <code>10</code>. <br><br>In the request, you can use the <b>offset</b> parameter in conjunction with the <b>limit</b> parameter to control the pagination of the output. For example, if <b>offset</b> is set to <code>30</code> and <b>limit</b> is set to <code>10</code>, the method retrieves transactions 31 thru 40 from the resulting collection of transactions. <br><br> <span class="tablenote"><strong>Note:</strong> This feature employs a zero-based list, where the first item in the list has an offset of <code>0</code>.</span><br><b>Default:</b> <code>0</code> (zero)
  --qp-sort: string # Sorting is not yet available for the <b>getTransactions</b> method. By default, monetary transactions that match the input criteria are sorted in descending order according to the transaction date. For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:SortField
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<href: string, limit: int, next: string, offset: int, prev: string, total: int, transactions: table<amount: record, bookingEntry: string, buyer: record, eBayCollectedTaxAmount: record, feeJurisdiction: record, feeType: string, orderId: string, orderLineItems: list, paymentsEntity: string, payoutId: string, references: list, salesRecordReference: string, totalFeeAmount: record, totalFeeBasisAmount: record, transactionDate: string, transactionId: string, transactionMemo: string, transactionStatus: string, transactionType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar") (serialize-qp "limit" $limit "scalar") (serialize-qp "offset" $offset "scalar") (serialize-qp "sort" $qp_sort "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transaction" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>The <b>getTransactionSummary</b> method retrieves cumulative information for monetary transactions. If applicable, the number of payments with a <code>transactionStatus</code> equal to <code>FUNDS_ON_HOLD</code> and the total monetary amount of these on-hold payments are also returned.<br><br><span class="tablenote"><b>Note:</b> For a complete list of transaction types, refer to <a href="/api-docs/sell/finances/types/pay:TransactionTypeEnum " target="_blank ">TransactionTypeEnum</a>.</span><br>Refer to the <a href="#uri.filter ">filter</a> field for additional information about each filter and its use.<br><br><span class="tablenote"><b>Note:</b> Unless a <code>transactionType</code> filter is used to retrieve a specific type of transaction (e.g., <code>SALE</code>, <code>REFUND</code>, etc.,) the <a href="#response.creditCount">creditCount</a> and <a href="#response.creditAmount">creditAmount</a> response fields both include <i>order sales</i> and <i>seller credits</i> information. That is, the <b>count</b> and <b>value</b> fields do not distinguish between these two types monetary transactions.</span>
#
# GET /transaction_summary
# operationId: getTransactionSummary
export def "transaction-summary get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --filter: string # Numerous filters are available for the <strong>getTransactionSummary</strong> method, and these filters are discussed below. One or more of these filter types can be used. The <b>transactionStatus</b> filter must be used. All other filters are optional. <ul><li><b>transactionStatus</b>: the data returned in the response pertains to the sales, payouts, and transfer status set. The supported <b>transactionStatus</b> values are as follows:<ul><li><code>PAYOUT</code>: only consider monetary transactions where the proceeds from the sales order(s) have been paid out to the seller's bank account.</li><li><code>FUNDS_PROCESSING</code>: only consider monetary transactions where the proceeds from the sales order(s) are currently being processed.</li><li><code>FUNDS_AVAILABLE_FOR_PAYOUT</code>: only consider monetary transactions where the proceeds from the sales order(s) are available for a seller payout, but processing has not yet begun.</li><li><code>FUNDS_ON_HOLD</code>: only consider monetary transactions where the proceeds from the sales order(s) are currently being held by eBay, and are not yet available for a seller payout.</li><li><code>COMPLETED</code>: this indicates that the funds for the corresponding <code>TRANSFER</code> monetary transaction have transferred and the transaction has completed.</li><li><code>FAILED</code>: this indicates the process has failed for the corresponding <code>TRANSFER</code> monetary transaction. </li></ul>Below is the proper syntax to use when setting up the <b>transactionStatus</b> filter: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionStatus:&#123;PAYOUT&#125;</code></li><li><b>transactionDate</b>: only consider monetary transactions that occurred within a specific range of dates.<br><br><span class="tablenote"><strong>Note:</strong> All dates must be input using UTC format (<code>YYYY-MM-DDTHH:MM:SS.SSSZ</code>) and should be adjusted accordingly for the local timezone of the user.</span><br><br>Below is the proper syntax to use if filtering by a date range: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionDate:&#91;2018-10-23T00:00:01.000Z..2018-11-09T00:00:01.000Z&#93;</code><br><br>Alternatively, the user could omit the ending date, and the date range would include the starting date and up to 90 days past that date, or the current date if the starting date is less than 90 days in the past.</li>  <li><b>transactionType</b>: only consider a specific type of monetary transaction. The supported <b>transactionType</b> values are as follows:<ul><li><code>SALE</code>: a sales order.</li><li> <code>REFUND</code>: a refund to the buyer after an order cancellation or return.</li><li><code>CREDIT</code>: a credit issued by eBay to the seller's account.</li><li><code>DISPUTE</code>: a monetary transaction associated with a payment dispute between buyer and seller.</li><li><code>NON_SALE_CHARGE</code>: a monetary transaction involving a seller transferring money to eBay for the balance of a charge for NON_SALE_CHARGE transactions (transactions that contain non-transactional seller fees). These can include a one-time payment, monthly/yearly subscription fees charged monthly, NRC charges, and fee credits.</li><li><code>SHIPPING_LABEL</code>: a monetary transaction where eBay is billing the seller for an eBay shipping label. Note that the shipping label functionality will initially only be available to a select number of sellers.</li><li><code>TRANSFER</code>: A transfer is a monetary transaction where eBay is billing the seller for reimbursement of a charge. An example of a transfer is a seller reimbursing eBay for a buyer refund.</li><li><code>ADJUSTMENT</code>: An adjustment is a monetary transaction where eBay is crediting or debiting the seller's account.</li><li><code>WITHDRAWAL</code>: A withdrawal is a monetary transaction where the seller requests an on-demand payout from eBay.<br><br><span class="tablenote"><b>Note:</b> On-demand payout is not available for sellers who are already on a <b>daily</b> payout schedule. In order to initiate an on-demand payout, a seller must be on a <b>weekly</b>, <b>bi-weekly</b>, or <b>monthly</b> payout schedule.</span></li><li><code>LOAN_REPAYMENT</code>: A monetary transaction related to the repayment of an outstanding loan balance for approved participants enrolled in the <a href="https://pages.ebay.com/sellercapital/ " target="_blank ">eBay Seller Capital financing program</a>.<br><br><span class="tablenote"><b>Note:</b> eBay Seller Capital financing is only available in select marketplaces. Refer to <a href="/api-docs/sell/finances/overview.html#loans " target="_blank ">Marketplace availability for eBay Seller Capital funding program</a> for current marketplace eligibility.</span></li></ul>Below is the proper syntax to use if filtering by a monetary transaction type: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionType:{SALE}</code></li><li><b>buyerUsername</b>: only consider monetary transactions involving a specific buyer (specified with the buyer's eBay user ID). Below is the proper syntax to use if filtering by a specific eBay buyer: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=buyerUsername:&#123;buyer1234&#125;</code> </li><li><b>salesRecordReference</b>: only consider monetary transactions corresponding to a specific order (identified with a Selling Manager order identifier). Below is the proper syntax to use if filtering by a specific Selling Manager Sales Record ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=salesRecordReference:&#123;123&#125;</code><br><br><span class="tablenote"><strong>Note:</strong> For all orders originating after February 1, 2020, a value of <code>0</code> will be returned in the <b>salesRecordReference</b> field. So, this filter will only be useful to retrieve orders than occurred before this date.</span> </li><li><b>payoutId</b>: only consider monetary transactions related to a specific seller payout (identified with a Payout ID). This value is auto-generated by eBay once the seller payout is set to be processed. Below is the proper syntax to use if filtering by a specific Payout ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=payoutId:&#123;5********8&#125;</code>  </li><li><b>transactionId</b>: the unique identifier of a monetary transaction. For a sales order, the <b>orderId</b> filter should be used instead. Only the monetary transaction(s) associated with this <b>transactionId</b> value are returned.<br><br><span class="tablenote"><strong>Note:</strong> This filter cannot be used alone; the <b>transactionType</b> must also be specified when filtering by transaction ID.</span><br><br>Below is the proper syntax to use if filtering by a specific transaction ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=transactionId:{0*-0***0-3***3}&filter=transactionType:{SALE}</code> </li><li><b>orderId</b>: the unique identifier of a sales order. For any other monetary transaction, the <b>transactionId</b> filter should be used instead. Only the monetary transaction(s) associated with this <b>orderId</b> value are returned. Below is the proper syntax to use if filtering by a specific order ID: <br><br><code>https://apiz.ebay.com/sell/finances/v1/transaction_summary?filter=orderId:{0*-0***0-3***3}</code> </li></ul> For implementation help, refer to eBay API documentation at https://developer.ebay.com/api-docs/sell/finances/types/cos:FilterField
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<adjustmentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, adjustmentBookingEntry: string, adjustmentCount: int, balanceTransferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, balanceTransferBookingEntry: string, balanceTransferCount: int, creditAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, creditBookingEntry: string, creditCount: int, disputeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, disputeBookingEntry: string, disputeCount: int, loanRepaymentAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, loanRepaymentBookingEntry: string, loanRepaymentCount: int, nonSaleChargeAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, nonSaleChargeBookingEntry: string, nonSaleChargeCount: int, onHoldAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, onHoldBookingEntry: string, onHoldCount: int, refundAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, refundBookingEntry: string, refundCount: int, shippingLabelAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, shippingLabelBookingEntry: string, shippingLabelCount: int, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferBookingEntry: string, transferCount: int, withdrawalAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, withdrawalBookingEntry: string, withdrawalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transaction_summary" $qp)
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# <div class="msgbox_important"><p class="msgbox_importantInDiv" data-mc-autonum="&lt;b&gt;&lt;span style=&quot;color: #dd1e31;&quot; class=&quot;mcFormatColor&quot;&gt;Important! &lt;/span&gt;&lt;/b&gt;"><span class="autonumber"><span><b><span style="color: #dd1e31;" class="mcFormatColor">Important!</span></b></span></span> Due to EU &amp; UK Payments regulatory requirements, an additional security verification via Digital Signatures is required for certain API calls that are made on behalf of EU/UK sellers, including all <b>Finances API</b> methods. Please refer to <a href="/develop/guides/digital-signatures-for-apis " target="_blank">Digital Signatures for APIs</a> to learn more on the impacted APIs and the process to create signatures to be included in the HTTP payload.</p></div><br>This method retrieves detailed information regarding a <code>TRANSFER</code> transaction type. A <code>TRANSFER</code> is a  monetary transaction type that involves a seller transferring money to eBay for reimbursement of one or more charges. For example, when a seller reimburses eBay for a buyer refund.<br><br>If an ID is passed into the URI that is an identifier for another transaction type, this call will return an http status code of <code>404 Not found</code>.
#
# GET /transfer/{transfer_Id}
# operationId: getTransfer
export def "transfer get" [
  transfer_Id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-EBAY-C-MARKETPLACE-ID: string # This header identifies the seller's eBay marketplace. It is required for all marketplaces outside of the US. See <a href="/api-docs/static/rest-request-components.html#marketpl " target="_blank ">HTTP request headers</a> for the marketplace ID values.
]: nothing -> record<fundingSource: record<brand: string, memo: string, type: string>, transactionDate: string, transferAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>, transferDetail: record<balanceAdjustment: record<adjustmentAmount: record, adjustmentType: string>, charges: list<record>, totalChargeNetAmount: record<convertedFromCurrency: string, convertedFromValue: string, currency: string, exchangeRate: string, value: string>>, transferId: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transfer/($transfer_Id)")
  let extra_headers = {"X-EBAY-C-MARKETPLACE-ID": $X_EBAY_C_MARKETPLACE_ID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
