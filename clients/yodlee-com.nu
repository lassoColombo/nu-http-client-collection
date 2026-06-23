# Auto-generated client for Yodlee Core APIs v1.1.0
# Source: https://api.apis.guru/v2/specs/yodlee.com/1.1.0/openapi.json
# Auth: --token flag or $env.YODLEE_CORE_APIS_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o YODLEE_CORE_APIS_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "none" => { {scheme: $scheme, headers: {}, query: "", location: "none"} }
    _ => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
  }
}

# Serialize a single query parameter based on collection style
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let is_list = ($value | describe | str starts-with "list")
  if $is_list and ($value | is-empty) { return [] }
  let n = (encode-path-segment $name)
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

# Serialize an array-typed path parameter (issue 49.A). OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build URL from base, path, and optional query string
def build-url [base: string, path: string, query?: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let result = ($parsed | upsert path $full_path)
  if ($query != null) and ($query | is-not-empty) { $result | upsert query $query | url join } else { $result | url join }
}

# Build the dry-run record returned by --dry-run. Shape:
#   {dry_run: true, method, url, query: <record>, headers, body, content_type, timeout,
#    auth: {scheme, location}}
# `meta` carries logical-form data (the query record by spec name, the pre-serialization
# body) that do-request itself cannot reconstruct from its wire-format args.
def build-dry-run-record [method: string, url: string, auth: record, content_type: string, timeout: duration, meta?: record]: nothing -> record {
  let m = ($meta | default {})
  {
    dry_run: true
    method: $method
    url: $url
    query: ($m | get -o query | default {})
    headers: $auth.headers
    body: ($m | get -o body)
    content_type: $content_type
    timeout: $timeout
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
}

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any, dry_run_meta?: record]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return (build-dry-run-record $method $req_url $auth $ct $timeout $dry_run_meta) }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method == "head") and (not $full) and (not $allow_errors) and $resp.status < 400 { return $resp.headers }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "accounts get-list" } } | get name | first)
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
export def "accounts get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountIds.
  --container: string # bank/creditCard/investment/insurance/loan/reward/realEstate/otherAssets/otherLiabilities
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefreshNote:fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
  --provider-account-id: string # Comma separated providerAccountIds.
  --request-id: string # The unique identifier that returns contextual data
  --status: string # ACTIVE,INACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> record<account: table<401kLoan: record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar") (serialize-qp "requestId" $request_id "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "container": $container, "include": $include, "providerAccountId": $provider_account_id, "requestId": $request_id, "status": $status} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName: string, accountNumber?: string, accountType: string, address?: record, amountDue?: record, balance?: record, dueDate?: string, frequency?: "DAILY"|"ONE_TIME"|"WEEKLY"|"EVERY_2_WEEKS"|"SEMI_MONTHLY"|"MONTHLY"|"QUARTERLY"|"SEMI_ANNUALLY"|"ANNUALLY"|"EVERY_2_MONTHS"|"EBILL"|"FIRST_DAY_MONTHLY"|"LAST_DAY_MONTHLY"|"EVERY_4_WEEKS"|"UNKNOWN"|"OTHER", homeValue?: record, includeInNetWorth?: string, memo?: string, nickname?: string, valuationType?: "SYSTEM"|"MANUAL"}
]: any -> record<account: table<accountName: string, accountNumber: string, id: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts")
  let req_body = {"account": $account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Evaluate Address
#
# POST /accounts/evaluateAddress
# operationId: evaluateAddress
# --address shape: {address1?: string, address2?: string, address3?: string, city?: string, country?: string, sourceType?: string, state?: string, street: string, type?: "HOME"|"BUSINESS"|"POBOX"|"RETAIL"|"OFFICE"|"SMALL_BUSINESS"|"COMMUNICATION"|"PERMANENT"|"STATEMENT_ADDRESS"|"PAYMENT"|"PAYOFF"|"UNKNOWN", zip?: string}
export def "accounts-evaluate-address create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  address: record # shape: {address1?: string, address2?: string, address3?: string, city?: string, country?: string, sourceType?: string, state?: string, street: string, type?: "HOME"|"BUSINESS"|"POBOX"|"RETAIL"|"OFFICE"|"SMALL_BUSINESS"|"COMMUNICATION"|"PERMANENT"|"STATEMENT_ADDRESS"|"PAYMENT"|"PAYOFF"|"UNKNOWN", zip?: string}
]: any -> record<address: table<address1: string, address2: string, address3: string, city: string, country: string, sourceType: string, state: string, street: string, type: string, zip: string>, isValidAddress: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/accounts/evaluateAddress")
  let req_body = {"address": $address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include-cf: oneof<nothing, bool> # Consider carry forward logic for missing balances
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> record<account: table<historicalBalances: list, id: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "includeCF" $include_cf "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/accounts/historicalBalances" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "fromDate": $from_date, "includeCF": $include_cf, "interval": $interval, "skip": $skip, "toDate": $to_date, "top": $top} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # profile, holder, fullAccountNumber, fullAccountNumberList, paymentProfile, autoRefreshNote:fullAccountNumber is deprecated and is replaced with fullAccountNumberList in include parameter and response.
]: nothing -> record<account: table<401kLoan: record, CONTAINER: string, accountName: string, accountNumber: string, accountStatus: string, accountType: string, address: record, aggregationSource: string, amountDue: record, annualPercentageYield: float, annuityBalance: record, apr: float, associatedProviderAccountId: list, autoRefresh: record, availableBalance: record, availableCash: record, availableCredit: record, balance: record, bankTransferCode: list, cash: record, cashApr: float, cashValue: record, classification: string, collateral: string, coverage: list, createdDate: string, currentBalance: record, currentLevel: string, dataset: list, deathBenefit: record, derivedApr: float, displayedName: string, dueDate: string, enrollmentDate: string, escrowBalance: record, estimatedDate: string, expirationDate: string, faceAmount: record, frequency: string, fullAccountNumber: string, fullAccountNumberList: record, guarantor: string, holder: list, homeInsuranceType: string, homeValue: record, id: int, includeInNetWorth: bool, interestPaidLastYear: record, interestPaidYTD: record, interestRate: float, interestRateType: string, isAsset: bool, isManual: bool, lastEmployeeContributionAmount: record, lastEmployeeContributionDate: string, lastPayment: record, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, lender: string, lifeInsuranceType: string, loanPayByDate: string, loanPayoffAmount: record, loanPayoffDetails: record, marginBalance: record, maturityAmount: record, maturityDate: string, memo: string, minimumAmountDue: record, moneyMarketBalance: record, nextLevel: string, nickname: string, oauthMigrationStatus: string, originalLoanAmount: record, originationDate: string, overDraftLimit: record, paymentProfile: record, policyEffectiveDate: string, policyFromDate: string, policyStatus: string, policyTerm: string, policyToDate: string, premium: record, premiumPaymentTerm: string, primaryRewardUnit: string, principalBalance: record, profile: record, providerAccountId: int, providerId: string, providerName: string, recurringPayment: record, remainingBalance: record, repaymentPlanType: string, rewardBalance: list, runningBalance: record, shortBalance: record, sourceAccountStatus: string, sourceId: string, term: string, totalCashLimit: record, totalCreditLimit: record, totalCreditLine: record, totalUnvestedBalance: record, totalVestedBalance: record, userClassification: string, valuationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include} | compact), body: null}
}

# Update Account
#
# PUT /accounts/{accountId}
# operationId: updateAccount
# --account shape: {accountName?: string, accountNumber?: string, accountStatus?: "ACTIVE"|"INACTIVE"|"TO_BE_CLOSED"|"CLOSED"|"DELETED", address?: record, amountDue?: record, balance?: record, container?: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", dueDate?: string, ... (6 more fields)}
export def "accounts update" [
  account_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  account: record # shape: {accountName?: string, accountNumber?: string, accountStatus?: "ACTIVE"|"INACTIVE"|"TO_BE_CLOSED"|"CLOSED"|"DELETED", address?: record, amountDue?: record, balance?: record, container?: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", dueDate?: string, ... (6 more fields)}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($account_id | is-empty) { error make --unspanned { msg: "path parameter 'accountId' must be non-empty" } }
  let full_url = (build-url $base ({account_id: (encode-path-segment $account_id)} | format pattern "/accounts/{account_id}"))
  let req_body = {"account": $account} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/apiKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate API Key
#
# POST /auth/apiKey
# operationId: generateApiKey
export def "auth-api-key generate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --public-key: string # Public key uploaded by the customer while generating ApiKey.Endpoints:GET /auth/apiKeyPOST /auth/apiKey
]: any -> record<apiKey: table<createdDate: string, expiresIn: int, key: string, publicKey: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/apiKey")
  let req_body = {"publicKey": $public_key} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($key | is-empty) { error make --unspanned { msg: "path parameter 'key' must be non-empty" } }
  let full_url = (build-url $base ({key: (encode-path-segment $key)} | format pattern "/auth/apiKey/{key}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate Access Token
#
# POST /auth/token
# operationId: generateAccessToken
export def "auth-token generate-access" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<token: record<accessToken: string, expiresIn: int, issuedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/auth/token")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> record<event: table<callbackUrl: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/cobrand/config/notifications/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eventName": $event_name} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/cobrand/config/notifications/events/{event_name}"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cobrand Login
#
# POST /cobrand/login
# operationId: cobrandLogin
# --cobrand shape: {cobrandLogin: string, cobrandPassword: string, locale?: string}
export def "cobrand-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  cobrand: record # shape: {cobrandLogin: string, cobrandPassword: string, locale?: string}
]: any -> record<applicationId: string, cobrandId: int, locale: string, session: record<cobSession: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cobrand/login")
  let req_body = {"cobrand": $cobrand} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Cobrand Logout
#
# POST /cobrand/logout
# operationId: cobrandLogout
export def "cobrand-logout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cobrand/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<keyAlias: string, keyAsPemString: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/cobrand/publicKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string@event-name-completer # eventName
]: nothing -> record<event: table<callbackUrl: string, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/configs/notifications/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eventName": $event_name} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/configs/notifications/events/{event_name}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/configs/notifications/events/{event_name}"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  event: record # shape: {callbackUrl?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let full_url = (build-url $base ({event_name: (encode-path-segment $event_name)} | format pattern "/configs/notifications/events/{event_name}"))
  let req_body = {"event": $event} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Public Key
#
# GET /configs/publicKey
# operationId: getPublicEncryptionKey
export def "configs-public-key get-encryption" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<publicKey: record<alias: string, key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/configs/publicKey")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --event-name: string # Event Name
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ)
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ)
]: nothing -> record<event: record<data: record<fromDate: string, toDate: string, userCount: int, userData: list>, info: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "eventName" $event_name "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataExtracts/events" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"eventName": $event_name, "fromDate": $from_date, "toDate": $to_date} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --from-date: string # From DateTime (YYYY-MM-DDThh:mm:ssZ)
  --login-name: string # Login Name
  --to-date: string # To DateTime (YYYY-MM-DDThh:mm:ssZ)
]: nothing -> record<userData: table<account: list, holding: list, providerAccount: list, totalTransactionsCount: int, transaction: list, user: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $from_date "scalar") (serialize-qp "loginName" $login_name "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/dataExtracts/userData" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fromDate": $from_date, "loginName": $login_name, "toDate": $to_date} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # Comma separated accountIds
  --classification-type: string # e.g. Country, Sector, etc.
  --include: string # details
]: nothing -> record<holdingSummary: table<account: list, classificationType: string, classificationValue: string, holding: list, value: record>, link: record<holdings: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountIds" $account_ids "scalar") (serialize-qp "classificationType" $classification_type "scalar") (serialize-qp "include" $include "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/holdingSummary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountIds": $account_ids, "classificationType": $classification_type, "include": $include} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-ids: string # comma separated accountIds
  --container: string # bank/creditCard/investment/insurance/loan/realEstate/otherAssets/otherLiabilities
  --from-date: string # from date for balance retrieval (YYYY-MM-DD)
  --include: string # details
  --interval: string # D-daily, W-weekly or M-monthly
  --skip: int # skip (Min 0) (format: int32)
  --to-date: string # toDate for balance retrieval (YYYY-MM-DD)
  --top: int # top (Max 500) (format: int32)
]: nothing -> record<networth: table<asset: record, date: string, historicalBalances: list, liability: record, networth: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountIds" $account_ids "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/networth" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountIds": $account_ids, "container": $container, "fromDate": $from_date, "include": $include, "interval": $interval, "skip": $skip, "toDate": $to_date, "top": $top} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: nothing -> record<links: record<transactions: string>, transactionSummary: table<categorySummary: list, categoryType: string, creditTotal: record, debitTotal: record, links: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "groupBy" $group_by "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "includeUserCategory" $include_user_category "scalar") (serialize-qp "interval" $interval "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/derived/transactionSummary" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "categoryId": $category_id, "categoryType": $category_type, "fromDate": $from_date, "groupBy": $group_by, "include": $include, "includeUserCategory": $include_user_category, "interval": $interval, "toDate": $to_date} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --keyword: string # The string used to search a document by its name.
  --account-id: string # The unique identifier of an account. Retrieve documents for a given accountId.
  --doc-type: string # Accepts only one of the following valid document types: STMT, TAX, and EBILL.
  --from-date: string # The date from which documents have to be retrieved.
  --to-date: string # The date to which documents have to be retrieved.
]: nothing -> record<document: table<accountID: int, docType: string, formType: string, id: string, lastUpdated: string, name: string, source: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Keyword" $keyword "scalar") (serialize-qp "accountId" $account_id "scalar") (serialize-qp "docType" $doc_type "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "toDate" $to_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/documents" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Keyword": $keyword, "accountId": $account_id, "docType": $doc_type, "fromDate": $from_date, "toDate": $to_date} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<document: table<docContent: string, id: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($document_id | is-empty) { error make --unspanned { msg: "path parameter 'documentId' must be non-empty" } }
  let full_url = (build-url $base ({document_id: (encode-path-segment $document_id)} | format pattern "/documents/{document_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --asset-classification-classification-type: string # e.g. Country, Sector, etc.
  --classification-value: string # e.g. US
  --include: string # assetClassification
  --provider-account-id: string # providerAccountId
]: nothing -> record<holding: table<accountId: int, accruedIncome: record, accruedInterest: record, assetClassification: list, contractQuantity: float, costBasis: record, couponRate: float, createdDate: string, cusipNumber: string, description: string, enrichedDescription: string, exercisedQuantity: float, expirationDate: string, grantDate: string, holdingType: string, id: int, interestRate: float, isShort: bool, isin: string, lastUpdated: string, matchStatus: string, maturityDate: string, optionType: string, price: record, providerAccountId: int, quantity: float, securityStyle: string, securityType: string, sedol: string, spread: record, strikePrice: record, symbol: string, term: string, unvestedQuantity: float, unvestedValue: record, value: record, vestedQuantity: float, vestedSharesExercisable: float, vestedValue: record, vestingDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "assetClassification.classificationType" $asset_classification_classification_type "scalar") (serialize-qp "classificationValue" $classification_value "scalar") (serialize-qp "include" $include "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/holdings" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "assetClassification.classificationType": $asset_classification_classification_type, "classificationValue": $classification_value, "include": $include, "providerAccountId": $provider_account_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<assetClassificationList: table<classificationType: string, classificationValue: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/holdings/assetClassificationList")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<holdingType: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/holdings/holdingTypeList")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --holding-id: string # Comma separated holdingId
]: nothing -> record<holding: table<id: string, security: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "holdingId" $holding_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/holdings/securities" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"holdingId": $holding_id} | compact), body: null}
}

# Get Provider Accounts
#
# GET /providerAccounts
# operationId: getAllProviderAccounts
export def "provider-accounts get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include
  --provider-ids: string # Comma separated providerIds.
]: nothing -> record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "providerIds" $provider_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include, "providerIds": $provider_ids} | compact), body: null}
}

# Update Account
#
# PUT /providerAccounts
# operationId: editCredentialsOrRefreshProviderAccount
# --dataset item shape: {attribute?: list, name?: "BASIC_AGG_DATA"|"ADVANCE_AGG_DATA"|"ACCT_PROFILE"|"DOCUMENT"}
# --field item shape: {id?: string, image?: string, value?: string}
# --preferences shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
export def "provider-accounts refresh-edit-credentials-or" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-ids: string # comma separated providerAccountIds
  --aggregation-source: string@aggregation-source-completer
  --consent-id: int # Consent Id generated for the request through POST Consent.Endpoints:POST Provider AccountPUT Provider Account (format: int64)
  --dataset: list # item shape: {attribute?: list, name?: "BASIC_AGG_DATA"|"ADVANCE_AGG_DATA"|"ACCT_PROFILE"|"DOCUMENT"}
  --dataset-name: list<string>
  field: list # item shape: {id?: string, image?: string, value?: string}
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> record<providerAccount: table<aggregationSource: string, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, providerId: int, requestId: string, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerAccountIds" $provider_account_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts" $qp)
  let req_body = {"aggregationSource": $aggregation_source, "consentId": $consent_id, "dataset": $dataset, "datasetName": $dataset_name, "field": $field, "preferences": $preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"providerAccountIds": $provider_account_ids} | compact), body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --provider-account-id: string # Comma separated providerAccountIds.
]: nothing -> record<providerAccount: table<id: int, profile: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "providerAccountId" $provider_account_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providerAccounts/profile" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"providerAccountId": $provider_account_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_account_id | is-empty) { error make --unspanned { msg: "path parameter 'providerAccountId' must be non-empty" } }
  let full_url = (build-url $base ({provider_account_id: (encode-path-segment $provider_account_id)} | format pattern "/providerAccounts/{provider_account_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --include: string # include credentials,questions
  --request-id: string # The unique identifier for the request that returns contextual data
]: nothing -> record<providerAccount: table<aggregationSource: string, consentId: int, createdDate: string, dataset: list, id: int, isManual: bool, lastUpdated: string, loginForm: list, oauthMigrationStatus: string, preferences: record, providerId: int, requestId: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_account_id | is-empty) { error make --unspanned { msg: "path parameter 'providerAccountId' must be non-empty" } }
  let qp = [(serialize-qp "include" $include "scalar") (serialize-qp "requestId" $request_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({provider_account_id: (encode-path-segment $provider_account_id)} | format pattern "/providerAccounts/{provider_account_id}") $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"include": $include, "requestId": $request_id} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --preferences: record # shape: {isAutoRefreshEnabled?: bool, isDataExtractsEnabled?: bool, linkedProviderAccountId?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_account_id | is-empty) { error make --unspanned { msg: "path parameter 'providerAccountId' must be non-empty" } }
  let full_url = (build-url $base ({provider_account_id: (encode-path-segment $provider_account_id)} | format pattern "/providerAccounts/{provider_account_id}/preferences"))
  let req_body = {"preferences": $preferences} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Providers
#
# GET /providers
# operationId: getAllProviders
export def "providers get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: nothing -> record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, forgetPasswordUrl: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginHelp: string, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "capability" $capability "scalar") (serialize-qp "dataset$filter" $dataset_filter "scalar") (serialize-qp "fullAccountNumberFields" $full_account_number_fields "scalar") (serialize-qp "institutionId" $institution_id "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "priority" $priority "scalar") (serialize-qp "providerId" $provider_id "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "top" $top "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"capability": $capability, "dataset$filter": $dataset_filter, "fullAccountNumberFields": $full_account_number_fields, "institutionId": $institution_id, "name": $name, "priority": $priority, "providerId": $provider_id, "skip": $skip, "top": $top} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # CHALLENGE_DEPOSIT_VERIFICATION - capability search is deprecated
  --dataset-filter: string # Expression to filter the providers by dataset(s) or dataset attribute(s). The default value will be the dataset or dataset attributes configured as default for the customer.
  --full-account-number-fields: string # Specify to filter the providers with values paymentAccountNumber,unmaskedAccountNumber.
  --name: string # Name in minimum 1 character or routing number.
  --priority: string # Search priority
]: nothing -> record<provider: record<TOTAL: record<count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "capability" $capability "scalar") (serialize-qp "dataset$filter" $dataset_filter "scalar") (serialize-qp "fullAccountNumberFields" $full_account_number_fields "scalar") (serialize-qp "name" $name "scalar") (serialize-qp "priority" $priority "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/count" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"capability": $capability, "dataset$filter": $dataset_filter, "fullAccountNumberFields": $full_account_number_fields, "name": $name, "priority": $priority} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<provider: table<PRIORITY: string, accountType: list, associatedProviderIds: list, authParameter: list, authType: string, baseUrl: string, capability: list, countryISOCode: string, dataset: list, favicon: string, help: string, id: int, isAddedByUser: string, isAutoRefreshEnabled: bool, isConsentRequired: bool, languageISOCode: string, lastModified: string, loginForm: list, loginUrl: string, logo: string, name: string, primaryLanguageISOCode: string, status: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_id | is-empty) { error make --unspanned { msg: "path parameter 'providerId' must be non-empty" } }
  let full_url = (build-url $base ({provider_id: (encode-path-segment $provider_id)} | format pattern "/providers/{provider_id}"))
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # accountId
  --container: string # creditCard/loan/insurance
  --from-date: string # from date for statement retrieval (YYYY-MM-DD)
  --is-latest: string # isLatest (true/false)
  --status: string # ACTIVE,TO_BE_CLOSED,CLOSED
]: nothing -> record<statement: table<accountId: int, amountDue: record, apr: float, billingPeriodEnd: string, billingPeriodStart: string, cashAdvance: record, cashApr: float, dueDate: string, id: int, interestAmount: record, isLatest: bool, lastPaymentAmount: record, lastPaymentDate: string, lastUpdated: string, loanBalance: record, minimumPayment: record, newCharges: record, principalAmount: record, statementDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "isLatest" $is_latest "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/statements" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "container": $container, "fromDate": $from_date, "isLatest": $is_latest, "status": $status} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: nothing -> record<transaction: table<CONTAINER: string, accountId: int, amount: record, baseType: string, category: string, categoryId: int, categorySource: string, categoryType: string, checkNumber: string, commission: record, createdDate: string, cusipNumber: string, date: string, description: record, detailCategoryId: int, highLevelCategoryId: int, holdingDescription: string, id: int, interest: record, isManual: bool, isin: string, lastUpdated: string, memo: string, merchant: record, parentCategoryId: int, postDate: string, price: record, principal: record, quantity: float, runningBalance: record, sedol: string, settleDate: string, sourceId: string, sourceType: string, status: string, subType: string, symbol: string, transactionDate: string, type: string, valoren: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "baseType" $base_type "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "detailCategoryId" $detail_category_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "highLevelCategoryId" $high_level_category_id "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "skip" $skip "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "top" $top "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "baseType": $base_type, "categoryId": $category_id, "categoryType": $category_type, "container": $container, "detailCategoryId": $detail_category_id, "fromDate": $from_date, "highLevelCategoryId": $high_level_category_id, "keyword": $keyword, "skip": $skip, "toDate": $to_date, "top": $top, "type": $type} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<transactionCategory: table<category: string, classification: string, defaultCategoryName: string, defaultHighLevelCategoryName: string, detailCategory: list, highLevelCategoryId: int, highLevelCategoryName: string, id: int, source: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create Category
#
# POST /transactions/categories
# operationId: createTransactionCategory
export def "transactions-categories create-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --category-name: string
  parent_category_id: int # format: int32
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories")
  let req_body = {"categoryName": $category_name, "parentCategoryId": $parent_category_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Update Category
#
# PUT /transactions/categories
# operationId: updateTransactionCategory
export def "transactions-categories update-category" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"categoryName": $category_name, "highLevelCategoryName": $high_level_category_name, "id": $id, "source": $body_source} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/rules
# DEPRECATED
# operationId: getTransactionCategorizationRulesDeprecated
@deprecated
export def "transactions-categories-rules get-categorization-deprecated" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<categoryLevelId: int, memId: int, ruleClauses: list<record>, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories/rules")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create or Run Transaction Categorization Rule
#
# POST /transactions/categories/rules
# operationId: createOrRunTransactionCategorizationRules
export def "transactions-categories-rules create-or-run-categorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"action": $action, "ruleParam": $rule_param} | compact), body: null}
}

# Delete Transaction Categorization Rule
#
# DELETE /transactions/categories/rules/{ruleId}
# operationId: deleteTransactionCategorizationRule
export def "transactions-categories-rules delete-categorization" [
  rule_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/transactions/categories/rules/{rule_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Run Transaction Categorization Rule
#
# POST /transactions/categories/rules/{ruleId}
# operationId: runTransactionCategorizationRule
export def "transactions-categories-rules create-run-categorization" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --action: string@action-completer # default: run
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let qp = [(serialize-qp "action" $action "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/transactions/categories/rules/{rule_id}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"action": $action} | compact), body: null}
}

# Update Transaction Categorization Rule
#
# PUT /transactions/categories/rules/{ruleId}
# operationId: updateTransactionCategorizationRule
# --rule shape: {categoryId: int, priority?: int, ruleClause: list, source?: "SYSTEM"|"USER"}
export def "transactions-categories-rules update-categorization" [
  rule_id: int
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  rule: record # shape: {categoryId: int, priority?: int, ruleClause: list, source?: "SYSTEM"|"USER"}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($rule_id | is-empty) { error make --unspanned { msg: "path parameter 'ruleId' must be non-empty" } }
  let full_url = (build-url $base ({rule_id: (encode-path-segment $rule_id)} | format pattern "/transactions/categories/rules/{rule_id}"))
  let req_body = {"rule": $rule} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Transaction Categorization Rules
#
# GET /transactions/categories/txnRules
# operationId: getTransactionCategorizationRules
export def "transactions-categories-txn-rules get-categorization" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<txnRules: table<categoryLevelId: int, memId: int, ruleClauses: list, rulePriority: int, transactionCategorisationId: int, userDefinedRuleId: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transactions/categories/txnRules")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Delete Category
#
# DELETE /transactions/categories/{categoryId}
# operationId: deleteTransactionCategory
export def "transactions-categories delete-category" [
  category_id: int
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($category_id | is-empty) { error make --unspanned { msg: "path parameter 'categoryId' must be non-empty" } }
  let full_url = (build-url $base ({category_id: (encode-path-segment $category_id)} | format pattern "/transactions/categories/{category_id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: nothing -> record<transaction: record<TOTAL: record<count: int>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "baseType" $base_type "scalar") (serialize-qp "categoryId" $category_id "scalar") (serialize-qp "categoryType" $category_type "scalar") (serialize-qp "container" $container "scalar") (serialize-qp "detailCategoryId" $detail_category_id "scalar") (serialize-qp "fromDate" $from_date "scalar") (serialize-qp "highLevelCategoryId" $high_level_category_id "scalar") (serialize-qp "keyword" $keyword "scalar") (serialize-qp "toDate" $to_date "scalar") (serialize-qp "type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/transactions/count" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "baseType": $base_type, "categoryId": $category_id, "categoryType": $category_type, "container": $container, "detailCategoryId": $detail_category_id, "fromDate": $from_date, "highLevelCategoryId": $high_level_category_id, "keyword": $keyword, "toDate": $to_date, "type": $type} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  transaction: record # shape: {categoryId: int, categorySource: "SYSTEM"|"USER", container: "bank"|"creditCard"|"investment"|"insurance"|"loan"|"reward"|"realEstate"|"otherAssets"|"otherLiabilities", description?: record, memo?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($transaction_id | is-empty) { error make --unspanned { msg: "path parameter 'transactionId' must be non-empty" } }
  let full_url = (build-url $base ({transaction_id: (encode-path-segment $transaction_id)} | format pattern "/transactions/{transaction_id}"))
  let req_body = {"transaction": $transaction} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<user: record<address: record<address1: string, address2: string, address3: string, city: string, country: string, state: string, zip: string>, email: string, id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, segmentName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, name?: record, preferences?: record, segmentName?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user")
  let req_body = {"user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --app-ids: string # appIds
]: nothing -> record<user: record<accessTokens: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "appIds" $app_ids "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/accessTokens" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"appIds": $app_ids} | compact), body: null}
}

# User Logout
#
# POST /user/logout
# operationId: userLogout
export def "user-logout create" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/logout")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  user: record # shape: {address?: record, email?: string, loginName: string, name?: record, preferences?: record, segmentName?: string}
]: any -> record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/register")
  let req_body = {"user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Saml Login
#
# POST /user/samlLogin
# operationId: samlLogin
export def "user-saml-login create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --issuer: string # issuer
  --saml-response: string # samlResponse
  --qp-source: string # source
]: nothing -> record<user: record<id: int, loginName: string, name: record<first: string, fullName: string, last: string, middle: string>, preferences: record<currency: string, dateFormat: string, locale: string, timeZone: string>, roleType: string, session: record<userSession: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "issuer" $issuer "scalar") (serialize-qp "samlResponse" $saml_response "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/user/samlLogin" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"issuer": $issuer, "samlResponse": $saml_response, "source": $qp_source} | compact), body: null}
}

# Delete User
#
# DELETE /user/unregister
# operationId: unregister
export def "user-unregister delete" [
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
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/user/unregister")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Verification Status
#
# GET /verification
# operationId: getVerificationStatus
export def "verification get-status" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: string # Comma separated accountId
  --provider-account-id: string # Comma separated providerAccountId
  --verification-type: string # verificationType
]: nothing -> record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, remainingAttempts: int, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountId" $account_id "scalar") (serialize-qp "providerAccountId" $provider_account_id "scalar") (serialize-qp "verificationType" $verification_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/verification" $qp)
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"accountId": $account_id, "providerAccountId": $provider_account_id, "verificationType": $verification_type} | compact), body: null}
}

# Initiaite Matching Service and Challenge Deposit
#
# POST /verification
# operationId: initiateMatchingOrChallengeDepositeVerification
# --verification shape: {account?: record, accountId?: int, providerAccountId?: int, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
export def "verification create-initiate-matching-or-challenge-deposite" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verification")
  let req_body = {"verification": $verification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --verification: record # shape: {account?: record, accountId?: int, providerAccountId?: int, transaction: list, verificationType?: "MATCHING"|"CHALLENGE_DEPOSIT"}
]: any -> record<verification: table<account: record, accountId: int, providerAccountId: int, reason: string, verificationDate: string, verificationId: int, verificationStatus: string, verificationType: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/verification")
  let req_body = {"verification": $verification} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Verify Accounts Using Transactions
#
# POST /verifyAccount/{providerAccountId}
# operationId: initiateAccountVerification
# --transactionCriteria item shape: {amount: float, baseType?: "CREDIT"|"DEBIT", date: string, dateVariance?: string, keyword?: string}
export def "verify-account create-initiate-verification" [
  provider_account_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --account-id: int # format: int64
  --container: string@container-completer
  transaction_criteria: list # item shape: {amount: float, baseType?: "CREDIT"|"DEBIT", date: string, dateVariance?: string, keyword?: string}
]: any -> record<verifyAccount: record<account: list<record>, transactionCriteria: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($provider_account_id | is-empty) { error make --unspanned { msg: "path parameter 'providerAccountId' must be non-empty" } }
  let full_url = (build-url $base ({provider_account_id: (encode-path-segment $provider_account_id)} | format pattern "/verifyAccount/{provider_account_id}"))
  let req_body = {"accountId": $account_id, "container": $container, "transactionCriteria": $transaction_criteria} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json;charset=UTF-8"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
