# Auto-generated client for Account API v6
# Source: https://api.apis.guru/v2/specs/adyen.com/AccountService/6/openapi.json
# Auth: --token flag or $env.ACCOUNT_API_TOKEN

const BASE_URL = "https://cal-test.adyen.com/cal/services/Account/v6"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ACCOUNT_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://cal-test.adyen.com/cal/services/Account/v6"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def account-state-type-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }
def payout-schedule-completer [] { ["BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT" "DAILY" "DAILY_AU" "DAILY_EU" "DAILY_SG" "DAILY_US" "HOLD" "MONTHLY" "WEEKLY" "WEEKLY_MON_TO_FRI_AU" "WEEKLY_MON_TO_FRI_EU" "WEEKLY_MON_TO_FRI_US" "WEEKLY_ON_TUE_FRI_MIDNIGHT" "WEEKLY_SUN_TO_THU_AU" "WEEKLY_SUN_TO_THU_US"] }
def payout-speed-completer [] { ["INSTANT" "SAME_DAY" "STANDARD"] }
def legal-entity-completer [] { ["Business" "Individual" "NonProfit" "Partnership" "PublicCompany"] }
def state-type-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "check-account-holder create" } } | get name | first)
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

# Trigger verification
#
# POST /checkAccountHolder
# operationId: post-checkAccountHolder
export def "check-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to verify.
  account_state_type: string@account-state-type-completer # The state required for the account holder. > Permitted values: `Processing`, `Payout`.
  tier: int # The tier required for the account holder. (format: int32)
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checkAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code, "accountStateType": $account_state_type, "tier": $tier} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Close an account
#
# POST /closeAccount
# operationId: post-closeAccount
export def "close-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of account to be closed.
]: any -> record<accountCode: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeAccount")
  let req_body = {"accountCode": $account_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Close an account holder
#
# POST /closeAccountHolder
# operationId: post-closeAccountHolder
export def "close-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder to be closed.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Close stores
#
# POST /closeStores
# operationId: post-closeStores
export def "close-stores create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder.
  stores: list<string> # List of stores to be closed.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeStores")
  let req_body = {"accountHolderCode": $account_holder_code, "stores": $stores} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create an account
#
# POST /createAccount
# operationId: post-createAccount
export def "create-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of Account Holder under which to create the account.
  --bank-account-uuid: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payout-method-code: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payout-schedule: string@payout-schedule-completer # The payout schedule of the prospective account. >Permitted values: `DEFAULT`, `HOLD`, `DAILY`, `WEEKLY`, `MONTHLY`.
  --payout-schedule-reason: string # The reason for the payout schedule choice. >Required if the payoutSchedule is `HOLD`.
  --payout-speed: string@payout-speed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`. (default: STANDARD)
]: any -> record<accountCode: string, accountHolderCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createAccount")
  let req_body = {"accountHolderCode": $account_holder_code, "bankAccountUUID": $bank_account_uuid, "description": $description, "metadata": $metadata, "payoutMethodCode": $payout_method_code, "payoutSchedule": $payout_schedule, "payoutScheduleReason": $payout_schedule_reason, "payoutSpeed": $payout_speed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Create an account holder
#
# POST /createAccountHolder
# operationId: post-createAccountHolder
# --accountHolderDetails shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
@deprecated --flag primary-currency
export def "create-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # Your unique identifier for the prospective account holder. The length must be between three (3) and fifty (50) characters long. Only letters, digits, and hyphens (-) are allowed.
  account_holder_details: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --create-default-account: oneof<nothing, bool> # If set to **true**, an account with the default options is automatically created for the account holder. By default, this field is set to **true**.
  --description: string # A description of the prospective account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  legal_entity: string@legal-entity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request. Possible values: **Business**, **Individual**, or **NonProfit**. * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list. * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primary-currency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), with which the prospective account holder primarily deals. (DEPRECATED)
  --processing-tier: int # The starting [processing tier](https://docs.adyen.com/marketplaces-and-platforms/classic/onboarding-and-verification/precheck-kyc-information) for the prospective account holder. (format: int32)
  --verification-profile: string # The identifier of the profile that applies to this entity.
]: any -> record<accountCode: string, accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code, "accountHolderDetails": $account_holder_details, "createDefaultAccount": $create_default_account, "description": $description, "legalEntity": $legal_entity, "primaryCurrency": $primary_currency, "processingTier": $processing_tier, "verificationProfile": $verification_profile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete bank accounts
#
# POST /deleteBankAccounts
# operationId: post-deleteBankAccounts
export def "delete-bank-accounts create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder from which to delete the Bank Account(s).
  bank_account_uui_ds: list<string> # The code(s) of the Bank Accounts to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteBankAccounts")
  let req_body = {"accountHolderCode": $account_holder_code, "bankAccountUUIDs": $bank_account_uui_ds} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete legal arrangements
#
# POST /deleteLegalArrangements
# operationId: post-deleteLegalArrangements
# --legalArrangements item shape: {legalArrangementCode: string, legalArrangementEntityCodes?: list<string>}
export def "delete-legal-arrangements create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder.
  legal_arrangements: list # List of legal arrangements. — item shape: {legalArrangementCode: string, legalArrangementEntityCodes?: list<string>}
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteLegalArrangements")
  let req_body = {"accountHolderCode": $account_holder_code, "legalArrangements": $legal_arrangements} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete payout methods
#
# POST /deletePayoutMethods
# operationId: post-deletePayoutMethods
export def "delete-payout-methods create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder, from which to delete the payout methods.
  payout_method_codes: list<string> # The codes of the payout methods to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deletePayoutMethods")
  let req_body = {"accountHolderCode": $account_holder_code, "payoutMethodCodes": $payout_method_codes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete shareholders
#
# POST /deleteShareholders
# operationId: post-deleteShareholders
export def "delete-shareholders create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder from which to delete the Shareholders.
  shareholder_codes: list<string> # The code(s) of the Shareholders to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteShareholders")
  let req_body = {"accountHolderCode": $account_holder_code, "shareholderCodes": $shareholder_codes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete signatories
#
# POST /deleteSignatories
# operationId: post-deleteSignatories
export def "delete-signatories create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder from which to delete the signatories.
  signatory_codes: list<string> # Array of codes of the signatories to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteSignatories")
  let req_body = {"accountHolderCode": $account_holder_code, "signatoryCodes": $signatory_codes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get an account holder
#
# POST /getAccountHolder
# operationId: post-getAccountHolder
export def "get-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-code: string # The code of the account of which to retrieve the details. > Required if no `accountHolderCode` is provided.
  --account-holder-code: string # The code of the account holder of which to retrieve the details. > Required if no `accountCode` is provided.
  --show-details: oneof<nothing, bool> # True if the request should return the account holder details
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, accounts: table<accountCode: string, bankAccountUUID: string, beneficiaryAccount: string, beneficiaryMerchantReference: string, description: string, metadata: record, payoutMethodCode: string, payoutSchedule: record, payoutSpeed: string, status: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, migrationData: record<accountHolderId: string, balancePlatform: string, migrated: bool, migratedAccounts: list<record>, migratedStores: list<record>, migrationDate: string>, primaryCurrency: string, pspReference: string, resultCode: string, systemUpToDateTime: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getAccountHolder")
  let req_body = {"accountCode": $account_code, "accountHolderCode": $account_holder_code, "showDetails": $show_details} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a tax form
#
# POST /getTaxForm
# operationId: post-getTaxForm
export def "get-tax-form create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The account holder code you provided when you created the account holder.
  form_type: string # Type of the requested tax form. For example, 1099-K.
  year: int # Applicable tax year in the YYYY format. (format: int32)
]: any -> record<content: string, contentType: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getTaxForm")
  let req_body = {"accountHolderCode": $account_holder_code, "formType": $form_type, "year": $year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get documents
#
# POST /getUploadedDocuments
# operationId: post-getUploadedDocuments
export def "get-uploaded-documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder for which to retrieve the documents.
  --bank-account-uuid: string # The code of the Bank Account for which to retrieve the documents.
  --shareholder-code: string # The code of the Shareholder for which to retrieve the documents.
]: any -> record<documentDetails: table<accountHolderCode: string, bankAccountUUID: string, description: string, documentType: string, filename: string, legalArrangementCode: string, legalArrangementEntityCode: string, shareholderCode: string, signatoryCode: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getUploadedDocuments")
  let req_body = {"accountHolderCode": $account_holder_code, "bankAccountUUID": $bank_account_uuid, "shareholderCode": $shareholder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Suspend an account holder
#
# POST /suspendAccountHolder
# operationId: post-suspendAccountHolder
export def "suspend-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to be suspended.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suspendAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Unsuspend an account holder
#
# POST /unSuspendAccountHolder
# operationId: post-unSuspendAccountHolder
export def "un-suspend-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder to be reinstated.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unSuspendAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an account
#
# POST /updateAccount
# operationId: post-updateAccount
# --payoutSchedule shape: {action?: "CLOSE"|"NOTHING"|"UPDATE", reason?: string, schedule: "BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT"|"DAILY"|"DAILY_AU"|"DAILY_EU"|"DAILY_SG"|"DAILY_US"|"HOLD"|"MONTHLY"|"WEEKLY"|"WEEKLY_MON_TO_FRI_AU"|"WEEKLY_MON_TO_FRI_EU"|"WEEKLY_MON_TO_FRI_US"|"WEEKLY_ON_TUE_FRI_MIDNIGHT"|"WEEKLY_SUN_TO_THU_AU"|"WEEKLY_SUN_TO_THU_US"}
export def "update-account create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of the account to update.
  --bank-account-uuid: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters.You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payout-method-code: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payout-schedule: record # shape: {action?: "CLOSE"|"NOTHING"|"UPDATE", reason?: string, schedule: "BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT"|"DAILY"|"DAILY_AU"|"DAILY_EU"|"DAILY_SG"|"DAILY_US"|"HOLD"|"MONTHLY"|"WEEKLY"|"WEEKLY_MON_TO_FRI_AU"|"WEEKLY_MON_TO_FRI_EU"|"WEEKLY_MON_TO_FRI_US"|"WEEKLY_ON_TUE_FRI_MIDNIGHT"|"WEEKLY_SUN_TO_THU_AU"|"WEEKLY_SUN_TO_THU_US"}
  --payout-speed: string@payout-speed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`.
]: any -> record<accountCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccount")
  let req_body = {"accountCode": $account_code, "bankAccountUUID": $bank_account_uuid, "description": $description, "metadata": $metadata, "payoutMethodCode": $payout_method_code, "payoutSchedule": $payout_schedule, "payoutSpeed": $payout_speed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update an account holder
#
# POST /updateAccountHolder
# operationId: post-updateAccountHolder
# --accountHolderDetails shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
@deprecated --flag primary-currency
export def "update-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder to be updated.
  --account-holder-details: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --description: string # A description of the account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --legal-entity: string@legal-entity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request. Possible values: **Business**, **Individual**, or **NonProfit**. * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list. * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primary-currency: string # The primary three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), to which the account holder should be updated. (DEPRECATED)
  --processing-tier: int # The processing tier to which the Account Holder should be updated. >The processing tier can not be lowered through this request. >Required if accountHolderDetails are not provided. (format: int32)
  --verification-profile: string # The identifier of the profile that applies to this entity.
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code, "accountHolderDetails": $account_holder_details, "description": $description, "legalEntity": $legal_entity, "primaryCurrency": $primary_currency, "processingTier": $processing_tier, "verificationProfile": $verification_profile} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Update payout or processing state
#
# POST /updateAccountHolderState
# operationId: post-updateAccountHolderState
export def "update-account-holder-state create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder on which to update the state.
  --disable: oneof<nothing, bool> # If true, disable the requested state. If false, enable the requested state.
  --reason: string # The reason that the state is being updated. >Required if the state is being disabled.
  state_type: string@state-type-completer # The state to be updated. >Permitted values are: `Processing`, `Payout`
]: any -> record<accountHolderCode: string, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccountHolderState")
  let req_body = {"accountHolderCode": $account_holder_code, "disable": $disable, "reason": $reason, "stateType": $state_type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Upload a document
#
# POST /uploadDocument
# operationId: post-uploadDocument
# --documentDetail shape: {accountHolderCode?: string, bankAccountUUID?: string, description?: string, documentType: "BANK_STATEMENT"|"BSN"|"COMPANY_REGISTRATION_SCREENING"|"CONSTITUTIONAL_DOCUMENT"|"DRIVING_LICENCE"|"DRIVING_LICENCE_BACK"|"DRIVING_LICENCE_FRONT"|"ID_CARD"|"ID_CARD_BACK"|"ID_CARD_FRONT"|"PASSPORT"|"PROOF_OF_RESIDENCY"|"SSN"|"SUPPORTING_DOCUMENTS", filename?: string, legalArrangementCode?: string, legalArrangementEntityCode?: string, shareholderCode?: string, signatoryCode?: string}
export def "upload-document create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  document_content: string # The content of the document, in Base64-encoded string format. To learn about document requirements, refer to [Verification checks](https://docs.adyen.com/marketplaces-and-platforms/classic/verification-checks).
  document_detail: record # shape: {accountHolderCode?: string, bankAccountUUID?: string, description?: string, documentType: "BANK_STATEMENT"|"BSN"|"COMPANY_REGISTRATION_SCREENING"|"CONSTITUTIONAL_DOCUMENT"|"DRIVING_LICENCE"|"DRIVING_LICENCE_BACK"|"DRIVING_LICENCE_FRONT"|"ID_CARD"|"ID_CARD_BACK"|"ID_CARD_FRONT"|"PASSPORT"|"PROOF_OF_RESIDENCY"|"SSN"|"SUPPORTING_DOCUMENTS", filename?: string, legalArrangementCode?: string, legalArrangementEntityCode?: string, shareholderCode?: string, signatoryCode?: string}
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploadDocument")
  let req_body = {"documentContent": $document_content, "documentDetail": $document_detail} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
