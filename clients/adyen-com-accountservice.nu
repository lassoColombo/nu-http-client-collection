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

def base-url-completer [] { ["https://cal-test.adyen.com/cal/services/Account/v6"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def accountStateType-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }
def payoutSchedule-completer [] { ["BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT" "DAILY" "DAILY_AU" "DAILY_EU" "DAILY_SG" "DAILY_US" "HOLD" "MONTHLY" "WEEKLY" "WEEKLY_MON_TO_FRI_AU" "WEEKLY_MON_TO_FRI_EU" "WEEKLY_MON_TO_FRI_US" "WEEKLY_ON_TUE_FRI_MIDNIGHT" "WEEKLY_SUN_TO_THU_AU" "WEEKLY_SUN_TO_THU_US"] }
def payoutSpeed-completer [] { ["INSTANT" "SAME_DAY" "STANDARD"] }
def legalEntity-completer [] { ["Business" "Individual" "NonProfit" "Partnership" "PublicCompany"] }
def stateType-completer [] { ["LimitedPayout" "LimitedProcessing" "LimitlessPayout" "LimitlessProcessing" "Payout" "Processing"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "check-account-holder post-checkAccountHolder" } } | get name | first)
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
export def "check-account-holder post-checkAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder to verify.
  accountStateType: string@accountStateType-completer # The state required for the account holder. > Permitted values: `Processing`, `Payout`.
  tier: int # The tier required for the account holder. (format: int32)
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/checkAccountHolder")
  let body = {accountHolderCode: $accountHolderCode, accountStateType: $accountStateType, tier: $tier} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close an account
#
# POST /closeAccount
# operationId: post-closeAccount
export def "close-account post-closeAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountCode: string # The code of account to be closed.
]: any -> record<accountCode: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeAccount")
  let body = {accountCode: $accountCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close an account holder
#
# POST /closeAccountHolder
# operationId: post-closeAccountHolder
export def "close-account-holder post-closeAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder to be closed.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeAccountHolder")
  let body = {accountHolderCode: $accountHolderCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Close stores
#
# POST /closeStores
# operationId: post-closeStores
export def "close-stores post-closeStores" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder.
  stores: list # List of stores to be closed.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/closeStores")
  let body = {accountHolderCode: $accountHolderCode, stores: $stores} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an account
#
# POST /createAccount
# operationId: post-createAccount
export def "create-account post-createAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of Account Holder under which to create the account.
  --bankAccountUUID: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payoutMethodCode: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payoutSchedule: string@payoutSchedule-completer # The payout schedule of the prospective account. >Permitted values: `DEFAULT`, `HOLD`, `DAILY`, `WEEKLY`, `MONTHLY`.
  --payoutScheduleReason: string # The reason for the payout schedule choice. >Required if the payoutSchedule is `HOLD`.
  --payoutSpeed: string@payoutSpeed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`. (default: STANDARD)
]: any -> record<accountCode: string, accountHolderCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string, status: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createAccount")
  let body = {accountHolderCode: $accountHolderCode, bankAccountUUID: $bankAccountUUID, description: $description, metadata: $metadata, payoutMethodCode: $payoutMethodCode, payoutSchedule: $payoutSchedule, payoutScheduleReason: $payoutScheduleReason, payoutSpeed: $payoutSpeed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create an account holder
#
# POST /createAccountHolder
# operationId: post-createAccountHolder
# --accountHolderDetails shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
@deprecated --flag primaryCurrency
export def "create-account-holder post-createAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # Your unique identifier for the prospective account holder. The length must be between three (3) and fifty (50) characters long. Only letters, digits, and hyphens (-) are allowed.
  accountHolderDetails: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --createDefaultAccount: oneof<nothing, bool> # If set to **true**, an account with the default options is automatically created for the account holder. By default, this field is set to **true**.
  --description: string # A description of the prospective account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  legalEntity: string@legalEntity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request.  Possible values: **Business**, **Individual**, or **NonProfit**.  * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list.  * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primaryCurrency: string # The three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), with which the prospective account holder primarily deals. (DEPRECATED)
  --processingTier: int # The starting [processing tier](https://docs.adyen.com/marketplaces-and-platforms/classic/onboarding-and-verification/precheck-kyc-information) for the prospective account holder. (format: int32)
  --verificationProfile: string # The identifier of the profile that applies to this entity.
]: any -> record<accountCode: string, accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/createAccountHolder")
  let body = {accountHolderCode: $accountHolderCode, accountHolderDetails: $accountHolderDetails, createDefaultAccount: $createDefaultAccount, description: $description, legalEntity: $legalEntity, primaryCurrency: $primaryCurrency, processingTier: $processingTier, verificationProfile: $verificationProfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete bank accounts
#
# POST /deleteBankAccounts
# operationId: post-deleteBankAccounts
export def "delete-bank-accounts post-deleteBankAccounts" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder from which to delete the Bank Account(s).
  bankAccountUUIDs: list # The code(s) of the Bank Accounts to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteBankAccounts")
  let body = {accountHolderCode: $accountHolderCode, bankAccountUUIDs: $bankAccountUUIDs} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete legal arrangements
#
# POST /deleteLegalArrangements
# operationId: post-deleteLegalArrangements
# --legalArrangements item shape: {legalArrangementCode: string, legalArrangementEntityCodes?: list}
export def "delete-legal-arrangements post-deleteLegalArrangements" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder.
  legalArrangements: list # List of legal arrangements. — item shape: {legalArrangementCode: string, legalArrangementEntityCodes?: list}
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteLegalArrangements")
  let body = {accountHolderCode: $accountHolderCode, legalArrangements: $legalArrangements} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete payout methods
#
# POST /deletePayoutMethods
# operationId: post-deletePayoutMethods
export def "delete-payout-methods post-deletePayoutMethods" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder, from which to delete the payout methods.
  payoutMethodCodes: list # The codes of the payout methods to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deletePayoutMethods")
  let body = {accountHolderCode: $accountHolderCode, payoutMethodCodes: $payoutMethodCodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete shareholders
#
# POST /deleteShareholders
# operationId: post-deleteShareholders
export def "delete-shareholders post-deleteShareholders" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder from which to delete the Shareholders.
  shareholderCodes: list # The code(s) of the Shareholders to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteShareholders")
  let body = {accountHolderCode: $accountHolderCode, shareholderCodes: $shareholderCodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete signatories
#
# POST /deleteSignatories
# operationId: post-deleteSignatories
export def "delete-signatories post-deleteSignatories" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder from which to delete the signatories.
  signatoryCodes: list # Array of codes of the signatories to be deleted.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/deleteSignatories")
  let body = {accountHolderCode: $accountHolderCode, signatoryCodes: $signatoryCodes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get an account holder
#
# POST /getAccountHolder
# operationId: post-getAccountHolder
export def "get-account-holder post-getAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accountCode: string # The code of the account of which to retrieve the details. > Required if no `accountHolderCode` is provided.
  --accountHolderCode: string # The code of the account holder of which to retrieve the details. > Required if no `accountCode` is provided.
  --showDetails: oneof<nothing, bool> # True if the request should return the account holder details
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, accounts: table<accountCode: string, bankAccountUUID: string, beneficiaryAccount: string, beneficiaryMerchantReference: string, description: string, metadata: record, payoutMethodCode: string, payoutSchedule: record, payoutSpeed: string, status: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, migrationData: record<accountHolderId: string, balancePlatform: string, migrated: bool, migratedAccounts: list<record>, migratedStores: list<record>, migrationDate: string>, primaryCurrency: string, pspReference: string, resultCode: string, systemUpToDateTime: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getAccountHolder")
  let body = {accountCode: $accountCode, accountHolderCode: $accountHolderCode, showDetails: $showDetails} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a tax form
#
# POST /getTaxForm
# operationId: post-getTaxForm
export def "get-tax-form post-getTaxForm" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The account holder code you provided when you created the account holder.
  formType: string # Type of the requested tax form. For example, 1099-K.
  year: int # Applicable tax year in the YYYY format. (format: int32)
]: any -> record<content: string, contentType: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getTaxForm")
  let body = {accountHolderCode: $accountHolderCode, formType: $formType, year: $year} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get documents
#
# POST /getUploadedDocuments
# operationId: post-getUploadedDocuments
export def "get-uploaded-documents post-getUploadedDocuments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder for which to retrieve the documents.
  --bankAccountUUID: string # The code of the Bank Account for which to retrieve the documents.
  --shareholderCode: string # The code of the Shareholder for which to retrieve the documents.
]: any -> record<documentDetails: table<accountHolderCode: string, bankAccountUUID: string, description: string, documentType: string, filename: string, legalArrangementCode: string, legalArrangementEntityCode: string, shareholderCode: string, signatoryCode: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/getUploadedDocuments")
  let body = {accountHolderCode: $accountHolderCode, bankAccountUUID: $bankAccountUUID, shareholderCode: $shareholderCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Suspend an account holder
#
# POST /suspendAccountHolder
# operationId: post-suspendAccountHolder
export def "suspend-account-holder post-suspendAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder to be suspended.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/suspendAccountHolder")
  let body = {accountHolderCode: $accountHolderCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Unsuspend an account holder
#
# POST /unSuspendAccountHolder
# operationId: post-unSuspendAccountHolder
export def "un-suspend-account-holder post-unSuspendAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the account holder to be reinstated.
]: any -> record<accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/unSuspendAccountHolder")
  let body = {accountHolderCode: $accountHolderCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an account
#
# POST /updateAccount
# operationId: post-updateAccount
# --payoutSchedule shape: {action?: "CLOSE"|"NOTHING"|"UPDATE", reason?: string, schedule: "BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT"|"DAILY"|"DAILY_AU"|"DAILY_EU"|"DAILY_SG"|"DAILY_US"|"HOLD"|"MONTHLY"|"WEEKLY"|"WEEKLY_MON_TO_FRI_AU"|"WEEKLY_MON_TO_FRI_EU"|"WEEKLY_MON_TO_FRI_US"|"WEEKLY_ON_TUE_FRI_MIDNIGHT"|"WEEKLY_SUN_TO_THU_AU"|"WEEKLY_SUN_TO_THU_US"}
export def "update-account post-updateAccount" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountCode: string # The code of the account to update.
  --bankAccountUUID: string # The bankAccountUUID of the bank account held by the account holder to couple the account with. Scheduled payouts in currencies matching the currency of this bank account will be sent to this bank account. Payouts in different currencies will be sent to a matching bank account of the account holder.
  --description: string # A description of the account, maximum 256 characters.You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --metadata: record # A set of key and value pairs for general use by the merchant. The keys do not have specific names and may be used for storing miscellaneous data as desired. > Note that during an update of metadata, the omission of existing key-value pairs will result in the deletion of those key-value pairs.
  --payoutMethodCode: string # The payout method code held by the account holder to couple the account with. Scheduled card payouts will be sent using this payout method code.
  --payoutSchedule: record # shape: {action?: "CLOSE"|"NOTHING"|"UPDATE", reason?: string, schedule: "BIWEEKLY_ON_1ST_AND_15TH_AT_MIDNIGHT"|"DAILY"|"DAILY_AU"|"DAILY_EU"|"DAILY_SG"|"DAILY_US"|"HOLD"|"MONTHLY"|"WEEKLY"|"WEEKLY_MON_TO_FRI_AU"|"WEEKLY_MON_TO_FRI_EU"|"WEEKLY_MON_TO_FRI_US"|"WEEKLY_ON_TUE_FRI_MIDNIGHT"|"WEEKLY_SUN_TO_THU_AU"|"WEEKLY_SUN_TO_THU_US"}
  --payoutSpeed: string@payoutSpeed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`.
]: any -> record<accountCode: string, bankAccountUUID: string, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, metadata: record, payoutMethodCode: string, payoutSchedule: record<nextScheduledPayout: string, schedule: string>, payoutSpeed: string, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccount")
  let body = {accountCode: $accountCode, bankAccountUUID: $bankAccountUUID, description: $description, metadata: $metadata, payoutMethodCode: $payoutMethodCode, payoutSchedule: $payoutSchedule, payoutSpeed: $payoutSpeed} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update an account holder
#
# POST /updateAccountHolder
# operationId: post-updateAccountHolder
# --accountHolderDetails shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
@deprecated --flag primaryCurrency
export def "update-account-holder post-updateAccountHolder" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder to be updated.
  --accountHolderDetails: record # shape: {address?: record, bankAccountDetails?: list, bankAggregatorDataReference?: string, businessDetails?: record, email?: string, fullPhoneNumber?: string, individualDetails?: record, lastReviewDate?: string, legalArrangements?: list, merchantCategoryCode?: string, metadata?: record, payoutMethods?: list, principalBusinessAddress?: record, storeDetails?: list, webAddress?: string}
  --description: string # A description of the account holder, maximum 256 characters. You can use alphanumeric characters (A-Z, a-z, 0-9), white spaces, and underscores `_`.
  --legalEntity: string@legalEntity-completer # The legal entity type of the account holder. This determines the information that should be provided in the request.  Possible values: **Business**, **Individual**, or **NonProfit**.  * If set to **Business** or **NonProfit**, then `accountHolderDetails.businessDetails` must be provided, with at least one entry in the `accountHolderDetails.businessDetails.shareholders` list.  * If set to **Individual**, then `accountHolderDetails.individualDetails` must be provided.
  --primaryCurrency: string # The primary three-character [ISO currency code](https://docs.adyen.com/development-resources/currency-codes), to which the account holder should be updated. (DEPRECATED)
  --processingTier: int # The processing tier to which the Account Holder should be updated. >The processing tier can not be lowered through this request.  >Required if accountHolderDetails are not provided. (format: int32)
  --verificationProfile: string # The identifier of the profile that applies to this entity.
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccountHolder")
  let body = {accountHolderCode: $accountHolderCode, accountHolderDetails: $accountHolderDetails, description: $description, legalEntity: $legalEntity, primaryCurrency: $primaryCurrency, processingTier: $processingTier, verificationProfile: $verificationProfile} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update payout or processing state
#
# POST /updateAccountHolderState
# operationId: post-updateAccountHolderState
export def "update-account-holder-state post-updateAccountHolderState" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  accountHolderCode: string # The code of the Account Holder on which to update the state.
  --disable: oneof<nothing, bool> # If true, disable the requested state.  If false, enable the requested state.
  --reason: string # The reason that the state is being updated. >Required if the state is being disabled.
  stateType: string@stateType-completer # The state to be updated. >Permitted values are: `Processing`, `Payout`
]: any -> record<accountHolderCode: string, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/updateAccountHolderState")
  let body = {accountHolderCode: $accountHolderCode, disable: $disable, reason: $reason, stateType: $stateType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a document
#
# POST /uploadDocument
# operationId: post-uploadDocument
# --documentDetail shape: {accountHolderCode?: string, bankAccountUUID?: string, description?: string, documentType: "BANK_STATEMENT"|"BSN"|"COMPANY_REGISTRATION_SCREENING"|"CONSTITUTIONAL_DOCUMENT"|"DRIVING_LICENCE"|"DRIVING_LICENCE_BACK"|"DRIVING_LICENCE_FRONT"|"ID_CARD"|"ID_CARD_BACK"|"ID_CARD_FRONT"|"PASSPORT"|"PROOF_OF_RESIDENCY"|"SSN"|"SUPPORTING_DOCUMENTS", filename?: string, legalArrangementCode?: string, legalArrangementEntityCode?: string, shareholderCode?: string, signatoryCode?: string}
export def "upload-document post-uploadDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  documentContent: string # The content of the document, in Base64-encoded string format.  To learn about document requirements, refer to [Verification checks](https://docs.adyen.com/marketplaces-and-platforms/classic/verification-checks).
  documentDetail: record # shape: {accountHolderCode?: string, bankAccountUUID?: string, description?: string, documentType: "BANK_STATEMENT"|"BSN"|"COMPANY_REGISTRATION_SCREENING"|"CONSTITUTIONAL_DOCUMENT"|"DRIVING_LICENCE"|"DRIVING_LICENCE_BACK"|"DRIVING_LICENCE_FRONT"|"ID_CARD"|"ID_CARD_BACK"|"ID_CARD_FRONT"|"PASSPORT"|"PROOF_OF_RESIDENCY"|"SSN"|"SUPPORTING_DOCUMENTS", filename?: string, legalArrangementCode?: string, legalArrangementEntityCode?: string, shareholderCode?: string, signatoryCode?: string}
]: any -> record<accountHolderCode: string, accountHolderDetails: record<address: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, bankAccountDetails: list<record>, bankAggregatorDataReference: string, businessDetails: record<doingBusinessAs: string, legalBusinessName: string, listedUltimateParentCompany: list, registrationNumber: string, shareholders: list, signatories: list, stockExchange: string, stockNumber: string, stockTicker: string, taxId: string>, email: string, fullPhoneNumber: string, individualDetails: record<name: record, personalData: record>, lastReviewDate: string, legalArrangements: list<record>, merchantCategoryCode: string, metadata: record, payoutMethods: list<record>, principalBusinessAddress: record<city: string, country: string, houseNumberOrName: string, postalCode: string, stateOrProvince: string, street: string>, storeDetails: list<record>, webAddress: string>, accountHolderStatus: record<events: list<record>, payoutState: record<allowPayout: bool, disableReason: string, disabled: bool, notAllowedReason: string, payoutLimit: record, tierNumber: int>, processingState: record<disableReason: string, disabled: bool, processedFrom: record, processedTo: record, tierNumber: int>, status: string, statusReason: string>, description: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, legalEntity: string, primaryCurrency: string, pspReference: string, resultCode: string, verification: record<accountHolder: record<checks: list>, legalArrangements: list<record>, legalArrangementsEntities: list<record>, payoutMethods: list<record>, shareholders: list<record>, signatories: list<record>, ultimateParentCompany: list<record>>, verificationProfile: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/uploadDocument")
  let body = {documentContent: $documentContent, documentDetail: $documentDetail} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
