# Auto-generated client for Fund API v6
# Source: https://api.apis.guru/v2/specs/adyen.com/FundService/6/openapi.json
# Auth: --token flag or $env.FUND_API_TOKEN

const BASE_URL = "https://cal-test.adyen.com/cal/services/Fund/v6"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FUND_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://cal-test.adyen.com/cal/services/Fund/v6"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def payout-speed-completer [] { ["INSTANT" "SAME_DAY" "STANDARD"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "account-holder-balance create" } } | get name | first)
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

# Get the balances of an account holder
#
# POST /accountHolderBalance
# operationId: post-accountHolderBalance
export def "account-holder-balance create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the Account Holder of which to retrieve the balance.
]: any -> record<balancePerAccount: table<accountCode: string, detailBalance: record>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string, totalBalance: record<balance: list<record>, onHoldBalance: list<record>, pendingBalance: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accountHolderBalance")
  let req_body = {"accountHolderCode": $account_holder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a list of transactions
#
# POST /accountHolderTransactionList
# operationId: post-accountHolderTransactionList
# --transactionListsPerAccount item shape: {accountCode: string, page: int}
export def "account-holder-transaction-list create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_holder_code: string # The code of the account holder that owns the account(s) of which retrieve the transaction list.
  --transaction-lists-per-account: list # A list of accounts to include in the transaction list. If left blank, the last fifty (50) transactions for all accounts of the account holder will be included. — item shape: {accountCode: string, page: int}
  --transaction-statuses: list<string> # A list of statuses to include in the transaction list. If left blank, all transactions will be included. >Permitted values: >* `PendingCredit` - a pending balance credit. >* `CreditFailed` - a pending credit failure; the balance will not be credited. >* `Credited` - a credited balance. >* `PendingDebit` - a pending balance debit (e.g., a refund). >* `CreditClosed` - a pending credit closed; the balance will not be credited. >* `CreditSuspended` - a pending credit closed; the balance will not be credited. >* `DebitFailed` - a pending debit failure; the balance will not be debited. >* `Debited` - a debited balance (e.g., a refund). >* `DebitReversedReceived` - a pending refund reversal. >* `DebitedReversed` - a reversed refund. >* `ChargebackReceived` - a received chargeback request. >* `Chargeback` - a processed chargeback. >* `ChargebackReversedReceived` - a pending chargeback reversal. >* `ChargebackReversed` - a reversed chargeback. >* `Converted` - converted. >* `ManualCorrected` - manual booking/adjustment by Adyen. >* `Payout` - a payout. >* `PayoutReversed` - a reversed payout. >* `PendingFundTransfer` - a pending transfer of funds from one account to another. >* `FundTransfer` - a transfer of funds from one account to another.
]: any -> record<accountTransactionLists: table<accountCode: string, hasNextPage: bool, transactions: list>, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accountHolderTransactionList")
  let req_body = {"accountHolderCode": $account_holder_code, "transactionListsPerAccount": $transaction_lists_per_account, "transactionStatuses": $transaction_statuses} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Send a direct debit request
#
# POST /debitAccountHolder
# operationId: post-debitAccountHolder
# --amount shape: {currency: string, value: int}
# --splits item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
export def "debit-account-holder create" [
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
  amount: record # shape: {currency: string, value: int}
  bank_account_uuid: string # The Adyen-generated unique alphanumeric identifier (UUID) of the account holder's bank account.
  --description: string # A description of the direct debit. Maximum length: 35 characters. Allowed characters: **a-z**, **A-Z**, **0-9**, and special characters **/?:().,'+ ";**.
  merchant_account: string # Your merchant account.
  splits: list # Contains instructions on how to split the funds between the accounts in your platform. The request must have at least one split item. — item shape: {account?: string, amount: record, description?: string, reference?: string, type: "BalanceAccount"|"Commission"|"Default"|"MarketPlace"|"PaymentFee"|"Remainder"|"Surcharge"|"Tip"|"VAT"|"Verification"}
]: any -> record<accountHolderCode: string, bankAccountUUID: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, merchantReferences: list<string>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/debitAccountHolder")
  let req_body = {"accountHolderCode": $account_holder_code, "amount": $amount, "bankAccountUUID": $bank_account_uuid, "description": $description, "merchantAccount": $merchant_account, "splits": $splits} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Pay out from an account to the account holder
#
# POST /payoutAccountHolder
# operationId: post-payoutAccountHolder
# --amount shape: {currency: string, value: int}
export def "payout-account-holder create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of the account from which the payout is to be made.
  account_holder_code: string # The code of the Account Holder who owns the account from which the payout is to be made. The Account Holder is the party to which the payout will be made.
  --amount: record # shape: {currency: string, value: int}
  --bank-account-uuid: string # The unique ID of the Bank Account held by the Account Holder to which the payout is to be made. If left blank, a bank account is automatically selected.
  --description: string # A description of the payout. Maximum 200 characters. Allowed: **abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789/?:().,'+ ";**
  --merchant-reference: string # A value that can be supplied at the discretion of the executing user in order to link multiple transactions to one another.
  --payout-method-code: string # The unique ID of the payout method held by the Account Holder to which the payout is to be made. If left blank, a payout instrument is automatically selected.
  --payout-speed: string@payout-speed-completer # Speed with which payouts for this account are processed. Permitted values: `STANDARD`, `SAME_DAY`. (default: STANDARD)
]: any -> record<bankAccountUUID: string, invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, merchantReference: string, payoutSpeed: string, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/payoutAccountHolder")
  let req_body = {"accountCode": $account_code, "accountHolderCode": $account_holder_code, "amount": $amount, "bankAccountUUID": $bank_account_uuid, "description": $description, "merchantReference": $merchant_reference, "payoutMethodCode": $payout_method_code, "payoutSpeed": $payout_speed} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Refund a funds transfer
#
# POST /refundFundsTransfer
# operationId: post-refundFundsTransfer
# --amount shape: {currency: string, value: int}
export def "refund-funds-transfer create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # shape: {currency: string, value: int}
  --merchant-reference: string # A value that can be supplied at the discretion of the executing user in order to link multiple transactions to one another.
  original_reference: string # A PSP reference of the original fund transfer.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, merchantReference: string, message: string, originalReference: string, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refundFundsTransfer")
  let req_body = {"amount": $amount, "merchantReference": $merchant_reference, "originalReference": $original_reference} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Refund all transactions of an account since the most recent payout
#
# POST /refundNotPaidOutTransfers
# operationId: post-refundNotPaidOutTransfers
export def "refund-not-paid-out-transfers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account_code: string # The code of the account from which to perform the refund(s).
  account_holder_code: string # The code of the Account Holder which owns the account from which to perform the refund(s).
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/refundNotPaidOutTransfers")
  let req_body = {"accountCode": $account_code, "accountHolderCode": $account_holder_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Designate a beneficiary account and transfer the benefactor's current balance
#
# POST /setupBeneficiary
# operationId: post-setupBeneficiary
export def "setup-beneficiary create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  destination_account_code: string # The destination account code.
  --merchant-reference: string # A value that can be supplied at the discretion of the executing user.
  source_account_code: string # The benefactor account.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/setupBeneficiary")
  let req_body = {"destinationAccountCode": $destination_account_code, "merchantReference": $merchant_reference, "sourceAccountCode": $source_account_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Transfer funds between platform accounts
#
# POST /transferFunds
# operationId: post-transferFunds
# --amount shape: {currency: string, value: int}
export def "transfer-funds create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  amount: record # shape: {currency: string, value: int}
  destination_account_code: string # The code of the account to which the funds are to be credited. >The state of the Account Holder of this account must be Active.
  --merchant-reference: string # A value that can be supplied at the discretion of the executing user in order to link multiple transactions to one another.
  source_account_code: string # The code of the account from which the funds are to be debited. >The state of the Account Holder of this account must be Active and allow payouts.
  transfer_code: string # The code related to the type of transfer being performed. >The permitted codes differ for each platform account and are defined in their service level agreement.
]: any -> record<invalidFields: table<errorCode: int, errorDescription: string, fieldType: record>, merchantReference: string, pspReference: string, resultCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transferFunds")
  let req_body = {"amount": $amount, "destinationAccountCode": $destination_account_code, "merchantReference": $merchant_reference, "sourceAccountCode": $source_account_code, "transferCode": $transfer_code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
