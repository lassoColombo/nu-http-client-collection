# Auto-generated client for Configuration API v2
# Source: https://api.apis.guru/v2/specs/adyen.com/BalancePlatformService/2/openapi.json
# Auth: --token flag or $env.CONFIGURATION_API_TOKEN

const BASE_URL = "https://balanceplatform-api-test.adyen.com/bcl/v2"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CONFIGURATION_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
    "basic-credentials" => { {headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: ""} }
    "none" => { {headers: {}, query: ""} }
    _ => { {headers: {Authorization: $"Bearer ($token_val)"}, query: ""} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($n)[(encode-path-segment $in.k)]=(encode-path-segment $in.v)" }) }
  if not $is_list { return [$"($n)=(encode-path-segment $value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
    "csv" => { let joined = ($value | each { encode-path-segment $in } | str join ","); [$"($n)=($joined)"] }
    "ssv" => { let joined = ($value | each { encode-path-segment $in } | str join "%20"); [$"($n)=($joined)"] }
    "tsv" => { let joined = ($value | each { encode-path-segment $in } | str join "%09"); [$"($n)=($joined)"] }
    "pipes" => { let joined = ($value | each { encode-path-segment $in } | str join "|"); [$"($n)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($n)[]=(encode-path-segment $v)" } }
    _ => { $value | each {|v| $"($n)=(encode-path-segment $v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://balanceplatform-api-test.adyen.com/bcl/v2"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def status-completer [] { ["active" "closed" "inactive" "suspended"] }
def category-completer [] { ["bank" "internal" "platformPayment"] }
def status-completer-1 [] { ["active" "inactive"] }
def type-completer [] { ["pull" "push"] }
def status-reason-completer [] { ["accountClosure" "damaged" "endOfLife" "expired" "lost" "other" "stolen" "suspectedFraud"] }
def type-completer-1 [] { ["bankAccount" "card"] }
def outcome-type-completer [] { ["hardBlock" "scoreBased"] }
def request-type-completer [] { ["authentication" "authorization" "tokenization"] }
def type-completer-2 [] { ["allowList" "blockList" "maxUsage" "velocity"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-holders create" } } | get name | first)
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

# Create an account holder
#
# POST /accountHolders
# operationId: post-accountHolders
# --contactDetails shape: {address: record, email: string, phone: record, webAddress?: string}
export def "account-holders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the account holder belongs. Required in the request if your API credentials can be used for multiple balance platforms.
  --capabilities: record # Contains key-value pairs that specify the actions that an account holder can do in your platform. The key is a capability required for your integration. For example, **issueCard** for Issuing. The value is an object containing the settings for the capability.
  --contact-details: record # shape: {address: record, email: string, phone: record, webAddress?: string}
  --description: string # Your description for the account holder, maximum 300 characters.
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) associated with the account holder. Adyen performs a verification process against the legal entity of the account holder.
  --reference: string # Your reference for the account holder, maximum 150 characters.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the account holder. For example, **Europe/Amsterdam**. Defaults to the time zone of the balance platform if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accountHolders")
  let req_body = {"balancePlatform": $balance_platform, "capabilities": $capabilities, "contactDetails": $contact_details, "description": $description, "legalEntityId": $legal_entity_id, "reference": $reference, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get an account holder
#
# GET /accountHolders/{id}
# operationId: get-accountHolders-id
export def "account-holders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accountHolders/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an account holder
#
# PATCH /accountHolders/{id}
# operationId: patch-accountHolders-id
# --contactDetails shape: {address: record, email: string, phone: record, webAddress?: string}
export def "account-holders update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the account holder belongs. Required in the request if your API credentials can be used for multiple balance platforms.
  --capabilities: record # Contains key-value pairs that specify the actions that an account holder can do in your platform. The key is a capability required for your integration. For example, **issueCard** for Issuing. The value is an object containing the settings for the capability.
  --contact-details: record # shape: {address: record, email: string, phone: record, webAddress?: string}
  --description: string # Your description for the account holder, maximum 300 characters.
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) associated with the account holder. Adyen performs a verification process against the legal entity of the account holder.
  --primary-balance-account: string # The ID of the account holder's primary balance account. By default, this is set to the first balance account that you create for the account holder. To assign a different balance account, send a PATCH request.
  --reference: string # Your reference for the account holder, maximum 150 characters.
  --status: string@status-completer # The status of the account holder. Possible values: * **active**: The account holder is active. This is the default status when creating an account holder. * **inactive (Deprecated)**: The account holder is temporarily inactive due to missing KYC details. You can set the account back to active by providing the missing KYC details. * **suspended**: The account holder is permanently deactivated by Adyen. This action cannot be undone. * **closed**: The account holder is permanently deactivated by you. This action cannot be undone.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the account holder. For example, **Europe/Amsterdam**. Defaults to the time zone of the balance platform if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> record<balancePlatform: string, capabilities: record, contactDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, email: string, phone: record<number: string, type: string>, webAddress: string>, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: table<capabilities: list, expiresAt: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accountHolders/{id}"))
  let req_body = {"balancePlatform": $balance_platform, "capabilities": $capabilities, "contactDetails": $contact_details, "description": $description, "legalEntityId": $legal_entity_id, "primaryBalanceAccount": $primary_balance_account, "reference": $reference, "status": $status, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get all balance accounts of an account holder
#
# GET /accountHolders/{id}/balanceAccounts
# operationId: get-accountHolders-id-balanceAccounts
export def "account-holders-balance-accounts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> record<balanceAccounts: table<accountHolderId: string, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string>, hasNext: bool, hasPrevious: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/accountHolders/{id}/balanceAccounts") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a balance account
#
# POST /balanceAccounts
# operationId: post-balanceAccounts
export def "balance-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_id: string # The unique identifier of the [account holder](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/accountHolders__resParam_id) associated with the balance account.
  --default-currency-code: string # The default three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) of the balance account. The default value is **EUR**.
  --description: string # A human-readable description of the balance account, maximum 300 characters. You can use this parameter to distinguish between multiple balance accounts under an account holder.
  --reference: string # Your reference for the balance account, maximum 150 characters.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the balance account. For example, **Europe/Amsterdam**. Defaults to the time zone of the account holder if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/balanceAccounts")
  let req_body = {"accountHolderId": $account_holder_id, "defaultCurrencyCode": $default_currency_code, "description": $description, "reference": $reference, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get all sweeps for a balance account
#
# GET /balanceAccounts/{balanceAccountId}/sweeps
# operationId: get-balanceAccounts-balanceAccountId-sweeps
export def "balance-accounts-sweeps list" [
  balance_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> record<hasNext: bool, hasPrevious: bool, sweeps: table<category: string, counterparty: record, currency: string, description: string, id: string, priorities: list, reason: string, schedule: any, status: string, sweepAmount: record, targetAmount: record, triggerAmount: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({balance_account_id: (encode-path-segment $balance_account_id)} | format pattern "/balanceAccounts/{balance_account_id}/sweeps") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a sweep
#
# POST /balanceAccounts/{balanceAccountId}/sweeps
# operationId: post-balanceAccounts-balanceAccountId-sweeps
# --counterparty shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
# --sweepAmount shape: {currency: string, value: int}
# --targetAmount shape: {currency: string, value: int}
# --triggerAmount shape: {currency: string, value: int}
export def "balance-accounts-sweeps create" [
  balance_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The type of transfer that results from the sweep. Possible values: - **bank**: Sweep to a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id). - **internal**: Transfer to another [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id) within your platform. Required when setting `priorities`.
  counterparty: record # shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
  currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) in uppercase. For example, **EUR**. The sweep currency must match any of the [balances currencies](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balanceAccounts/{id}__resParam_balances).
  --description: string # The message that will be used in the sweep transfer's description body with a maximum length of 140 characters. If the message is longer after replacing placeholders, the message will be cut off at 140 characters.
  --priorities: list<string> # The list of priorities for the bank transfer. This sets the speed at which the transfer is sent and the fees that you have to pay. You can provide multiple priorities. Adyen will try to pay out using the priority listed first, and if that's not possible, it moves on to the next option in the order of provided priorities. Possible values: * **regular**: For normal, low-value transactions. * **fast**: Faster way to transfer funds but has higher fees. Recommended for high-priority, low-value transactions. * **wire**: Fastest way to transfer funds but has the highest fees. Recommended for high-priority, high-value transactions. * **instant**: Instant way to transfer funds in [SEPA countries](https://www.ecb.europa.eu/paym/integration/retail/sepa/html/index.en.html). * **crossBorder**: High-value transfer to a recipient in a different country. * **internal**: Transfer to an Adyen-issued business bank account (by bank account number/IBAN). Set `category` to **bank**. For more details, see [optional priorities setup](https://docs.adyen.com/marketplaces-and-platforms/payout-to-users/scheduled-payouts#optional-priorities-setup).
  schedule: any # The schedule when the `triggerAmount` is evaluated. If the balance meets the threshold, funds are pushed out of or pulled in to the balance account.
  --status: string@status-completer-1 # The status of the sweep. If not provided, by default, this is set to **active**. Possible values: * **active**: the sweep is enabled and funds will be pulled in or pushed out based on the defined configuration. * **inactive**: the sweep is disabled and cannot be triggered.
  --sweep-amount: record # shape: {currency: string, value: int}
  --target-amount: record # shape: {currency: string, value: int}
  --trigger-amount: record # shape: {currency: string, value: int}
  --type: string@type-completer # The direction of sweep, whether pushing out or pulling in funds to the balance account. If not provided, by default, this is set to **push**. Possible values: * **push**: _push out funds_ to a destination balance account or transfer instrument. * **pull**: _pull in funds_ from a source merchant account, transfer instrument, or balance account. (default: push)
]: any -> record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({balance_account_id: (encode-path-segment $balance_account_id)} | format pattern "/balanceAccounts/{balance_account_id}/sweeps"))
  let req_body = {"category": $category, "counterparty": $counterparty, "currency": $currency, "description": $description, "priorities": $priorities, "schedule": $schedule, "status": $status, "sweepAmount": $sweep_amount, "targetAmount": $target_amount, "triggerAmount": $trigger_amount, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a sweep
#
# DELETE /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# operationId: delete-balanceAccounts-balanceAccountId-sweeps-sweepId
export def "balance-accounts-sweeps delete" [
  balance_account_id: string
  sweep_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({balance_account_id: (encode-path-segment $balance_account_id), sweep_id: (encode-path-segment $sweep_id)} | format pattern "/balanceAccounts/{balance_account_id}/sweeps/{sweep_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a sweep
#
# GET /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# operationId: get-balanceAccounts-balanceAccountId-sweeps-sweepId
export def "balance-accounts-sweeps get" [
  balance_account_id: string
  sweep_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({balance_account_id: (encode-path-segment $balance_account_id), sweep_id: (encode-path-segment $sweep_id)} | format pattern "/balanceAccounts/{balance_account_id}/sweeps/{sweep_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a sweep
#
# PATCH /balanceAccounts/{balanceAccountId}/sweeps/{sweepId}
# operationId: patch-balanceAccounts-balanceAccountId-sweeps-sweepId
# --counterparty shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
# --sweepAmount shape: {currency: string, value: int}
# --targetAmount shape: {currency: string, value: int}
# --triggerAmount shape: {currency: string, value: int}
export def "balance-accounts-sweeps update" [
  balance_account_id: string
  sweep_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category: string@category-completer # The type of transfer that results from the sweep. Possible values: - **bank**: Sweep to a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id). - **internal**: Transfer to another [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/balanceAccounts__resParam_id) within your platform. Required when setting `priorities`.
  counterparty: record # shape: {balanceAccountId?: string, merchantAccount?: string, transferInstrumentId?: string}
  currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) in uppercase. For example, **EUR**. The sweep currency must match any of the [balances currencies](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balanceAccounts/{id}__resParam_balances).
  --description: string # The message that will be used in the sweep transfer's description body with a maximum length of 140 characters. If the message is longer after replacing placeholders, the message will be cut off at 140 characters.
  --priorities: list<string> # The list of priorities for the bank transfer. This sets the speed at which the transfer is sent and the fees that you have to pay. You can provide multiple priorities. Adyen will try to pay out using the priority listed first, and if that's not possible, it moves on to the next option in the order of provided priorities. Possible values: * **regular**: For normal, low-value transactions. * **fast**: Faster way to transfer funds but has higher fees. Recommended for high-priority, low-value transactions. * **wire**: Fastest way to transfer funds but has the highest fees. Recommended for high-priority, high-value transactions. * **instant**: Instant way to transfer funds in [SEPA countries](https://www.ecb.europa.eu/paym/integration/retail/sepa/html/index.en.html). * **crossBorder**: High-value transfer to a recipient in a different country. * **internal**: Transfer to an Adyen-issued business bank account (by bank account number/IBAN). Set `category` to **bank**. For more details, see [optional priorities setup](https://docs.adyen.com/marketplaces-and-platforms/payout-to-users/scheduled-payouts#optional-priorities-setup).
  schedule: any # The schedule when the `triggerAmount` is evaluated. If the balance meets the threshold, funds are pushed out of or pulled in to the balance account.
  --status: string@status-completer-1 # The status of the sweep. If not provided, by default, this is set to **active**. Possible values: * **active**: the sweep is enabled and funds will be pulled in or pushed out based on the defined configuration. * **inactive**: the sweep is disabled and cannot be triggered.
  --sweep-amount: record # shape: {currency: string, value: int}
  --target-amount: record # shape: {currency: string, value: int}
  --trigger-amount: record # shape: {currency: string, value: int}
  --type: string@type-completer # The direction of sweep, whether pushing out or pulling in funds to the balance account. If not provided, by default, this is set to **push**. Possible values: * **push**: _push out funds_ to a destination balance account or transfer instrument. * **pull**: _pull in funds_ from a source merchant account, transfer instrument, or balance account. (default: push)
]: any -> record<category: string, counterparty: record<balanceAccountId: string, merchantAccount: string, transferInstrumentId: string>, currency: string, description: string, id: string, priorities: list<string>, reason: string, schedule: any, status: string, sweepAmount: record<currency: string, value: int>, targetAmount: record<currency: string, value: int>, triggerAmount: record<currency: string, value: int>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({balance_account_id: (encode-path-segment $balance_account_id), sweep_id: (encode-path-segment $sweep_id)} | format pattern "/balanceAccounts/{balance_account_id}/sweeps/{sweep_id}"))
  let req_body = {"category": $category, "counterparty": $counterparty, "currency": $currency, "description": $description, "priorities": $priorities, "schedule": $schedule, "status": $status, "sweepAmount": $sweep_amount, "targetAmount": $target_amount, "triggerAmount": $trigger_amount, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a balance account
#
# GET /balanceAccounts/{id}
# operationId: get-balanceAccounts-id
export def "balance-accounts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/balanceAccounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a balance account
#
# PATCH /balanceAccounts/{id}
# operationId: patch-balanceAccounts-id
export def "balance-accounts update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-id: string # The unique identifier of the [account holder](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/post/accountHolders__resParam_id) associated with the balance account.
  --default-currency-code: string # The default currency code of this balance account, in three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes) format. The default value is **EUR**.
  --description: string # A human-readable description of the balance account, maximum 300 characters. You can use this parameter to distinguish between multiple balance accounts under an account holder.
  --reference: string # Your reference to the balance account, maximum 150 characters.
  --status: string@status-completer # The status of the balance account. Payment instruments linked to the balance account can only be used if the balance account status is **active**. Possible values: **active**, **inactive**, **closed**, **suspended**.
  --time-zone: string # The [time zone](https://www.iana.org/time-zones) of the balance account. For example, **Europe/Amsterdam**. Defaults to the time zone of the account holder if no time zone is set. For possible values, see the [list of time zone codes](https://en.wikipedia.org/wiki/List_of_tz_database_time_zones).
]: any -> record<accountHolderId: string, balances: table<available: int, balance: int, currency: string, reserved: int>, defaultCurrencyCode: string, description: string, id: string, reference: string, status: string, timeZone: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/balanceAccounts/{id}"))
  let req_body = {"accountHolderId": $account_holder_id, "defaultCurrencyCode": $default_currency_code, "description": $description, "reference": $reference, "status": $status, "timeZone": $time_zone} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get all payment instruments for a balance account
#
# GET /balanceAccounts/{id}/paymentInstruments
# operationId: get-balanceAccounts-id-paymentInstruments
export def "balance-accounts-payment-instruments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> record<hasNext: bool, hasPrevious: bool, paymentInstruments: table<balanceAccountId: string, bankAccount: any, card: record, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/balanceAccounts/{id}/paymentInstruments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a balance platform
#
# GET /balancePlatforms/{id}
# operationId: get-balancePlatforms-id
export def "balance-platforms get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<description: string, id: string, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/balancePlatforms/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all account holders under a balance platform
#
# GET /balancePlatforms/{id}/accountHolders
# operationId: get-balancePlatforms-id-accountHolders
export def "balance-platforms-account-holders get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --offset: int # The number of items that you want to skip. (format: int32)
  --limit: int # The number of items returned per page, maximum 100 items. By default, the response returns 10 items per page. (format: int32)
]: nothing -> record<accountHolders: table<balancePlatform: string, capabilities: record, contactDetails: record, description: string, id: string, legalEntityId: string, primaryBalanceAccount: string, reference: string, status: string, timeZone: string, verificationDeadlines: list>, hasNext: bool, hasPrevious: bool> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "offset" $offset "scalar") (serialize-qp "limit" $limit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/balancePlatforms/{id}/accountHolders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a grant account
#
# GET /grantAccounts/{id}
# operationId: get-grantAccounts-id
export def "grant-accounts get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balances: table<currency: string, fee: int, principal: int, total: int>, fundingBalanceAccountId: string, id: string, limits: table<amount: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/grantAccounts/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all available grant offers
#
# GET /grantOffers
# operationId: get-grantOffers
export def "grant-offers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-holder-id: string # The unique identifier of the grant account.
]: nothing -> record<grantOffers: table<accountHolderId: string, amount: record, contractType: string, expiresAt: record, fee: record, id: string, repayment: record, startsAt: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountHolderId" $account_holder_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/grantOffers" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a grant offer
#
# GET /grantOffers/{grantOfferId}
# operationId: get-grantOffers-grantOfferId
export def "grant-offers get" [
  grant_offer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<accountHolderId: string, amount: record<currency: string, value: int>, contractType: string, expiresAt: record, fee: record<amount: record<currency: string, value: int>>, id: string, repayment: record<basisPoints: int, term: record<estimatedDays: int, maximumDays: int>, threshold: record<amount: record>>, startsAt: record> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({grant_offer_id: (encode-path-segment $grant_offer_id)} | format pattern "/grantOffers/{grant_offer_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a payment instrument group
#
# POST /paymentInstrumentGroups
# operationId: post-paymentInstrumentGroups
export def "payment-instrument-groups create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  balance_platform: string # The unique identifier of the [balance platform](https://docs.adyen.com/api-explorer/#/balanceplatform/latest/get/balancePlatforms/{id}__queryParam_id) to which the payment instrument group belongs.
  --description: string # Your description for the payment instrument group, maximum 300 characters.
  --properties: record # Properties of the payment instrument group.
  --reference: string # Your reference for the payment instrument group, maximum 150 characters.
  tx_variant: string # The tx variant of the payment instrument group.
]: any -> record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentInstrumentGroups")
  let req_body = {"balancePlatform": $balance_platform, "description": $description, "properties": $properties, "reference": $reference, "txVariant": $tx_variant} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a payment instrument group
#
# GET /paymentInstrumentGroups/{id}
# operationId: get-paymentInstrumentGroups-id
export def "payment-instrument-groups get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balancePlatform: string, description: string, id: string, properties: record, reference: string, txVariant: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstrumentGroups/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all transaction rules for a payment instrument group
#
# GET /paymentInstrumentGroups/{id}/transactionRules
# operationId: get-paymentInstrumentGroups-id-transactionRules
export def "payment-instrument-groups-transaction-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstrumentGroups/{id}/transactionRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a payment instrument
#
# POST /paymentInstruments
# operationId: post-paymentInstruments
# --card shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
export def "payment-instruments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  balance_account_id: string # The unique identifier of the [balance account](https://docs.adyen.com/api-explorer/#/balanceplatform/v1/post/balanceAccounts__resParam_id) associated with the payment instrument.
  --card: record # shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
  --description: string # Your description for the payment instrument, maximum 300 characters.
  issuing_country_code: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the payment instrument is issued. For example, **NL** or **US**.
  --payment-instrument-group-id: string # The unique identifier of the [payment instrument group](https://docs.adyen.com/api-explorer/#/balanceplatform/v1/post/paymentInstrumentGroups__resParam_id) to which the payment instrument belongs.
  --reference: string # Your reference for the payment instrument, maximum 150 characters.
  --status: string@status-completer # The status of the payment instrument. If a status is not specified when creating a payment instrument, it is set to **active** by default. However, there can be exceptions for cards based on the `card.formFactor` and the `issuingCountryCode`. For example, when issuing physical cards in the US, the default status is **inactive**. Possible values: * **active**: The payment instrument is active and can be used to make payments. * **inactive**: The payment instrument is inactive and cannot be used to make payments. * **suspended**: The payment instrument is suspended, either because it was stolen or lost. * **closed**: The payment instrument is permanently closed. This action cannot be undone.
  --status-reason: string@status-reason-completer # The reason for updating the status of the payment instrument. Possible values: **lost**, **stolen**, **damaged**, **suspectedFraud**, **expired**, **endOfLife**, **accountClosure**, **other**. If the reason is **other**, you must also send the `statusComment` parameter describing the status change.
  type: string@type-completer-1 # Type of payment instrument. Possible value: **card**, **bankAccount**.
]: any -> record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/paymentInstruments")
  let req_body = {"balanceAccountId": $balance_account_id, "card": $card, "description": $description, "issuingCountryCode": $issuing_country_code, "paymentInstrumentGroupId": $payment_instrument_group_id, "reference": $reference, "status": $status, "statusReason": $status_reason, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a payment instrument
#
# GET /paymentInstruments/{id}
# operationId: get-paymentInstruments-id
export def "payment-instruments get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusReason: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstruments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a payment instrument
#
# PATCH /paymentInstruments/{id}
# operationId: patch-paymentInstruments-id
# --card shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
export def "payment-instruments update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --balance-account-id: string # The unique identifier of the balance account associated with this payment instrument. >You can only change the balance account ID if the payment instrument has **inactive** status.
  --card: record # shape: {authentication?: record, brand: string, brandVariant: string, cardholderName: string, configuration?: record, deliveryContact?: record, formFactor: "physical"|"unknown"|"virtual"}
  --status: string@status-completer # The status of the payment instrument. If a status is not specified when creating a payment instrument, it is set to **active** by default. However, there can be exceptions for cards based on the `card.formFactor` and the `issuingCountryCode`. For example, when issuing physical cards in the US, the default status is **inactive**. Possible values: * **active**: The payment instrument is active and can be used to make payments. * **inactive**: The payment instrument is inactive and cannot be used to make payments. * **suspended**: The payment instrument is suspended, either because it was stolen or lost. * **closed**: The payment instrument is permanently closed. This action cannot be undone.
  --status-comment: string # Comment for the status of the payment instrument. Required if `statusReason` is **other**.
  --status-reason: string@status-reason-completer # The reason for updating the status of the payment instrument. Possible values: **lost**, **stolen**, **damaged**, **suspectedFraud**, **expired**, **endOfLife**, **accountClosure**, **other**. If the reason is **other**, you must also send the `statusComment` parameter describing the status change.
]: any -> record<balanceAccountId: string, bankAccount: any, card: record<authentication: record<email: string, password: string, phone: record>, bin: string, brand: string, brandVariant: string, cardholderName: string, configuration: record<activation: string, activationUrl: string, bulkAddress: record, cardImageId: string, carrier: string, carrierImageId: string, configurationProfileId: string, currency: string, envelope: string, insert: string, language: string, logoImageId: string, pinMailer: string, shipmentMethod: string>, cvc: string, deliveryContact: record<address: record, email: string, fullPhoneNumber: string, name: record, phoneNumber: record, webAddress: string>, expiration: record<month: string, year: string>, formFactor: string, lastFour: string, number: string>, description: string, id: string, issuingCountryCode: string, paymentInstrumentGroupId: string, reference: string, status: string, statusComment: string, statusReason: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstruments/{id}"))
  let req_body = {"balanceAccountId": $balance_account_id, "card": $card, "status": $status, "statusComment": $status_comment, "statusReason": $status_reason} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get the PAN of a payment instrument
#
# GET /paymentInstruments/{id}/reveal
# operationId: get-paymentInstruments-id-reveal
export def "payment-instruments-reveal get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<cvc: string, expiration: record<month: string, year: string>, pan: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstruments/{id}/reveal"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get all transaction rules for a payment instrument
#
# GET /paymentInstruments/{id}/transactionRules
# operationId: get-paymentInstruments-id-transactionRules
export def "payment-instruments-transaction-rules get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transactionRules: table<aggregationLevel: string, description: string, endDate: string, entityKey: record, id: string, interval: record, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record, score: int, startDate: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/paymentInstruments/{id}/transactionRules"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create a transaction rule
#
# POST /transactionRules
# operationId: post-transactionRules
# --entityKey shape: {entityReference?: string, entityType?: string}
# --interval shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
# --ruleRestrictions shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
export def "transaction-rules create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aggregation-level: string # The level at which data must be accumulated, used in rules with `type` **velocity** or **maxUsage**. The level must be the [same or lower in hierarchy](https://docs.adyen.com/issuing/transaction-rules#accumulate-data) than the `entityKey`. If not provided, by default, the rule will accumulate data at the **paymentInstrument** level. Possible values: **paymentInstrument**, **paymentInstrumentGroup**, **balanceAccount**, **accountHolder**, **balancePlatform**.
  description: string # Your description for the transaction rule, maximum 300 characters.
  --end-date: string # The date when the rule will stop being evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided, the rule will be evaluated until the rule status is set to **inactive**.
  entity_key: record # shape: {entityReference?: string, entityType?: string}
  interval: record # shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
  --outcome-type: string@outcome-type-completer # The [outcome](https://docs.adyen.com/issuing/transaction-rules#outcome) that will be applied when a transaction meets the conditions of the rule. If not provided, by default, this is set to **hardBlock**. Possible values: * **hardBlock**: the transaction is declined. * **scoreBased**: the transaction is assigned the `score` you specified. Adyen calculates the total score and if it exceeds 100, the transaction is declined.
  reference: string # Your reference for the transaction rule, maximum 150 characters.
  --request-type: string@request-type-completer # Indicates the type of request to which the rule applies. Possible values: **authorization**, **authentication**, **tokenization**.
  rule_restrictions: record # shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
  --score: int # A positive or negative score applied to the transaction if it meets the conditions of the rule. Required when `outcomeType` is **scoreBased**. The value must be between **-100** and **100**. (format: int32)
  --start-date: string # The date when the rule will start to be evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided when creating a transaction rule, the `startDate` is set to the date when the rule status is set to **active**.
  --status: string@status-completer-1 # The status of the transaction rule. If you provide a `startDate` in the request, the rule is automatically created with an **active** status. Possible values: **active**, **inactive**.
  type: string@type-completer-2 # The [type of rule](https://docs.adyen.com/issuing/transaction-rules#rule-types), which defines if a rule blocks transactions based on individual characteristics or accumulates data. Possible values: * **blockList**: decline a transaction when the conditions are met. * **maxUsage**: add the amount or number of transactions for the lifetime of a payment instrument, and then decline a transaction when the specified limits are met. * **velocity**: add the amount or number of transactions based on a specified time interval, and then decline a transaction when the specified limits are met.
]: any -> record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactionRules")
  let req_body = {"aggregationLevel": $aggregation_level, "description": $description, "endDate": $end_date, "entityKey": $entity_key, "interval": $interval, "outcomeType": $outcome_type, "reference": $reference, "requestType": $request_type, "ruleRestrictions": $rule_restrictions, "score": $score, "startDate": $start_date, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete a transaction rule
#
# DELETE /transactionRules/{transactionRuleId}
# operationId: delete-transactionRules-transactionRuleId
export def "transaction-rules delete" [
  transaction_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_rule_id: (encode-path-segment $transaction_rule_id)} | format pattern "/transactionRules/{transaction_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a transaction rule
#
# GET /transactionRules/{transactionRuleId}
# operationId: get-transactionRules-transactionRuleId
export def "transaction-rules get" [
  transaction_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transactionRule: record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record, brandVariants: record, countries: record, dayOfWeek: record, differentCurrencies: record, entryModes: record, internationalTransaction: record, matchingTransactions: record, mccs: record, merchantNames: record, merchants: record, processingTypes: record, timeOfDay: record, totalAmount: record>, score: int, startDate: string, status: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_rule_id: (encode-path-segment $transaction_rule_id)} | format pattern "/transactionRules/{transaction_rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update a transaction rule
#
# PATCH /transactionRules/{transactionRuleId}
# operationId: patch-transactionRules-transactionRuleId
# --entityKey shape: {entityReference?: string, entityType?: string}
# --interval shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
# --ruleRestrictions shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
export def "transaction-rules update" [
  transaction_rule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --aggregation-level: string # The level at which data must be accumulated, used in rules with `type` **velocity** or **maxUsage**. The level must be the [same or lower in hierarchy](https://docs.adyen.com/issuing/transaction-rules#accumulate-data) than the `entityKey`. If not provided, by default, the rule will accumulate data at the **paymentInstrument** level. Possible values: **paymentInstrument**, **paymentInstrumentGroup**, **balanceAccount**, **accountHolder**, **balancePlatform**.
  description: string # Your description for the transaction rule, maximum 300 characters.
  --end-date: string # The date when the rule will stop being evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided, the rule will be evaluated until the rule status is set to **inactive**.
  entity_key: record # shape: {entityReference?: string, entityType?: string}
  interval: record # shape: {dayOfMonth?: int, dayOfWeek?: "friday"|"monday"|"saturday"|"sunday"|"thursday"|"tuesday"|"wednesday", duration?: record, timeOfDay?: string, timeZone?: string, type: "daily"|"lifetime"|"monthly"|"perTransaction"|"rolling"|"sliding"|"weekly"}
  --outcome-type: string@outcome-type-completer # The [outcome](https://docs.adyen.com/issuing/transaction-rules#outcome) that will be applied when a transaction meets the conditions of the rule. If not provided, by default, this is set to **hardBlock**. Possible values: * **hardBlock**: the transaction is declined. * **scoreBased**: the transaction is assigned the `score` you specified. Adyen calculates the total score and if it exceeds 100, the transaction is declined.
  reference: string # Your reference for the transaction rule, maximum 150 characters.
  --request-type: string@request-type-completer # Indicates the type of request to which the rule applies. Possible values: **authorization**, **authentication**, **tokenization**.
  rule_restrictions: record # shape: {activeNetworkTokens?: record, brandVariants?: record, countries?: record, dayOfWeek?: record, differentCurrencies?: record, entryModes?: record, internationalTransaction?: record, matchingTransactions?: record, mccs?: record, merchantNames?: record, merchants?: record, processingTypes?: record, timeOfDay?: record, totalAmount?: record}
  --score: int # A positive or negative score applied to the transaction if it meets the conditions of the rule. Required when `outcomeType` is **scoreBased**. The value must be between **-100** and **100**. (format: int32)
  --start-date: string # The date when the rule will start to be evaluated, in ISO 8601 extended offset date-time format. For example, **2020-12-18T10:15:30+01:00**. If not provided when creating a transaction rule, the `startDate` is set to the date when the rule status is set to **active**.
  --status: string@status-completer-1 # The status of the transaction rule. If you provide a `startDate` in the request, the rule is automatically created with an **active** status. Possible values: **active**, **inactive**.
  type: string@type-completer-2 # The [type of rule](https://docs.adyen.com/issuing/transaction-rules#rule-types), which defines if a rule blocks transactions based on individual characteristics or accumulates data. Possible values: * **blockList**: decline a transaction when the conditions are met. * **maxUsage**: add the amount or number of transactions for the lifetime of a payment instrument, and then decline a transaction when the specified limits are met. * **velocity**: add the amount or number of transactions based on a specified time interval, and then decline a transaction when the specified limits are met.
]: any -> record<aggregationLevel: string, description: string, endDate: string, entityKey: record<entityReference: string, entityType: string>, id: string, interval: record<dayOfMonth: int, dayOfWeek: string, duration: record<unit: string, value: int>, timeOfDay: string, timeZone: string, type: string>, outcomeType: string, reference: string, requestType: string, ruleRestrictions: record<activeNetworkTokens: record<operation: string, value: int>, brandVariants: record<operation: string, value: list>, countries: record<operation: string, value: list>, dayOfWeek: record<operation: string, value: list>, differentCurrencies: record<operation: string, value: bool>, entryModes: record<operation: string, value: list>, internationalTransaction: record<operation: string, value: bool>, matchingTransactions: record<operation: string, value: int>, mccs: record<operation: string, value: list>, merchantNames: record<operation: string, value: list>, merchants: record<operation: string, value: list>, processingTypes: record<operation: string, value: list>, timeOfDay: record<operation: string, value: record>, totalAmount: record<operation: string, value: record>>, score: int, startDate: string, status: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transaction_rule_id: (encode-path-segment $transaction_rule_id)} | format pattern "/transactionRules/{transaction_rule_id}"))
  let req_body = {"aggregationLevel": $aggregation_level, "description": $description, "endDate": $end_date, "entityKey": $entity_key, "interval": $interval, "outcomeType": $outcome_type, "reference": $reference, "requestType": $request_type, "ruleRestrictions": $rule_restrictions, "score": $score, "startDate": $start_date, "status": $status, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Validate a bank account
#
# POST /validateBankAccountIdentification
# operationId: post-validateBankAccountIdentification
export def "validate-bank-account-identification create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_identification: any # Bank account identification.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/validateBankAccountIdentification")
  let req_body = {"accountIdentification": $account_identification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
