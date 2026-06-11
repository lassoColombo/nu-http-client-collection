# Auto-generated client for VAT (MTD) v1.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/vat-api/1.0/oas/resolved
# Auth: --token flag or $env.VAT_MTD_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o VAT_MTD_TOKEN | default "" }
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
  let is_list = ($value | describe | str starts-with "list")
  if ($value | describe | str starts-with "record") { return ($value | transpose k v | each { $"($name)[($in.k)]=($in.v)" }) }
  if not $is_list { return [$"($name)=($value)"] }
  match $style {
    "multi" => { $value | each {|v| $"($name)=($v)" } }
    "csv" => { let joined = ($value | each { $in | into string } | str join ","); [$"($name)=($joined)"] }
    "ssv" => { let joined = ($value | each { $in | into string } | str join "%20"); [$"($name)=($joined)"] }
    "tsv" => { let joined = ($value | each { $in | into string } | str join "\t"); [$"($name)=($joined)"] }
    "pipes" => { let joined = ($value | each { $in | into string } | str join "|"); [$"($name)=($joined)"] }
    "deepObject" => { $value | each {|v| $"($name)[]=($v)" } }
    _ => { $value | each {|v| $"($name)=($v)" } }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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

def bool-completer [] { ["'true'" "'false'"] }
def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organisations-vat-obligations RetrieveVATobligations" } } | get name | first)
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

# Retrieve VAT obligations
#
# GET /organisations/vat/{vrn}/obligations
# operationId: RetrieveVATobligations
export def "organisations-vat-obligations RetrieveVATobligations" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Date from which to return obligations. Mandatory unless the status is O. (e.g. 2017-01-25)
  --qp-to: string # Date to which to return obligations. Mandatory unless the status is O. (e.g. 2017-01-25)
  --status: string # Obligation status to return: O=Open, F= Fulfilled. Omit status to retrieve all obligations. (e.g. F)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<obligations: table<start: string, end: string, due: string, status: string, received: string, periodKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar") (serialize-qp "status" $status "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organisations/vat/($vrn)/obligations" $qp)
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit VAT return for period
#
# POST /organisations/vat/{vrn}/returns
# operationId: SubmitVATreturnforperiod
export def "organisations-vat-returns SubmitVATreturnforperiod" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
  periodKey: string # The ID code for the period that this obligation belongs to. The format is a string of four alphanumeric characters. Occasionally the format includes the # symbol.
  vatDueSales: float # Defines a monetary value (to 2 decimal places), between -9,999,999,999,999.99 and 9,999,999,999,999.99
  vatDueAcquisitions: float # Defines a monetary value (to 2 decimal places), between -9,999,999,999,999.99 and 9,999,999,999,999.99
  totalVatDue: float # The sum of the *vatDueSales* and *vatDueAcquisitions* values.  Defines a monetary value (to 2 decimal places), between -9,999,999,999,999.99 and 9,999,999,999,999.99
  vatReclaimedCurrPeriod: float # Defines a monetary value (to 2 decimal places), between -9,999,999,999,999.99 and 9,999,999,999,999.99
  netVatDue: float # The absolute difference between the *totalVatDue* and *vatReclaimedCurrPeriod* values. This should therefore be a positive number, calculated by subtracting the smallest value from the largest. HMRC will automatically determine whether the number represents net VAT that is due or net VAT that can be reclaimed.  Defines a monetary value (to 2 decimal places), between 0 and 99,999,999,999.99
  totalValueSalesExVAT: float # Defines a monetary value (to 2 zeroed decimal places), between -9,999,999,999,999.00 and 9,999,999,999,999.00
  totalValuePurchasesExVAT: float # Defines a monetary value (to 2 zeroed decimal places), between -9,999,999,999,999.00 and 9,999,999,999,999.00
  totalValueGoodsSuppliedExVAT: float # Defines a monetary value (to 2 zeroed decimal places), between -9,999,999,999,999.00 and 9,999,999,999,999.00
  totalAcquisitionsExVAT: float # Defines a monetary value (to 2 zeroed decimal places), between -9,999,999,999,999.00 and 9,999,999,999,999.00
  --finalised: string@bool-completer # Declaration that the user has finalised their VAT return. (e.g. true)
]: any -> record<processingDate: string, formBundleNumber: string, paymentIndicator: string, chargeRefNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/vat/($vrn)/returns")
  let body = {periodKey: $periodKey, vatDueSales: $vatDueSales, vatDueAcquisitions: $vatDueAcquisitions, totalVatDue: $totalVatDue, vatReclaimedCurrPeriod: $vatReclaimedCurrPeriod, netVatDue: $netVatDue, totalValueSalesExVAT: $totalValueSalesExVAT, totalValuePurchasesExVAT: $totalValuePurchasesExVAT, totalValueGoodsSuppliedExVAT: $totalValueGoodsSuppliedExVAT, totalAcquisitionsExVAT: $totalAcquisitionsExVAT, finalised: $finalised} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# View VAT Return
#
# GET /organisations/vat/{vrn}/returns/{periodKey}
# operationId: ViewVATReturn
export def "organisations-vat-returns ViewVATReturn" [
  vrn: string
  periodKey: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<periodKey: string, vatDueSales: float, vatDueAcquisitions: float, totalVatDue: float, vatReclaimedCurrPeriod: float, netVatDue: float, totalValueSalesExVAT: float, totalValuePurchasesExVAT: float, totalValueGoodsSuppliedExVAT: float, totalAcquisitionsExVAT: float> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/vat/($vrn)/returns/($periodKey)")
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve VAT liabilities
#
# GET /organisations/vat/{vrn}/liabilities
# operationId: RetrieveVATliabilities
export def "organisations-vat-liabilities RetrieveVATliabilities" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Liabilities to return from date, the minimum 'from' date is 2017-12-01 (e.g. 2018-01-25)
  --qp-to: string # Liabilities to return up to date, the maximum 'to' date is the current date (e.g. 2018-12-31)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<liabilities: table<taxPeriod: record, type: string, originalAmount: float, outstandingAmount: float, due: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organisations/vat/($vrn)/liabilities" $qp)
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve VAT payments
#
# GET /organisations/vat/{vrn}/payments
# operationId: RetrieveVATpayments
export def "organisations-vat-payments RetrieveVATpayments" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --qp-from: string # Payments to return from date, the minimum 'from' date is 2017-12-01 (e.g. 2018-01-25)
  --qp-to: string # Payments to return up to date, the maximum 'to' date is the current date (e.g. 2018-12-31)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<payments: table<amount: float, received: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "from" $qp_from "scalar") (serialize-qp "to" $qp_to "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/organisations/vat/($vrn)/payments" $qp)
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve VAT penalties
#
# GET /organisations/vat/{vrn}/penalties
# operationId: RetrieveVATpenalties
export def "organisations-vat-penalties RetrieveVATpenalties" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<totalisations: record<lateSubmissionPenaltyTotalValue: float, penalisedPrincipalTotal: float, latePaymentPenaltyPostedTotal: float, latePaymentPenaltyEstimateTotal: float>, lateSubmissionPenalty: record<summary: record<activePenaltyPoints: float, inactivePenaltyPoints: float, periodOfComplianceAchievement: string, regimeThreshold: float, penaltyChargeAmount: float>, details: list<record>>, latePaymentPenalty: record<details: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/vat/($vrn)/penalties")
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve financial details
#
# GET /organisations/vat/{vrn}/financial-details/{penaltyChargeReference}
# operationId: Retrievefinancialdetails
export def "organisations-vat-financial-details Retrievefinancialdetails" [
  vrn: string
  penaltyChargeReference: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<totalisations: record<totalOverdue: float, totalNotYetDue: float, totalBalance: float, totalCredit: float, totalCleared: float, additionalReceivableTotalisations: record<totalAccountPostedInterest: float, totalAccountAccruingInterest: float>>, documentDetails: table<postingDate: string, issueDate: string, documentInterestTotals: record, documentTotalAmount: float, documentClearedAmount: float, documentOutstandingAmount: float, lineItemDetails: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/vat/($vrn)/financial-details/($penaltyChargeReference)")
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve VAT customer information
#
# GET /organisations/vat/{vrn}/information
# operationId: RetrieveVATCustomerInformation
export def "organisations-vat-information RetrieveVATCustomerInformation" [
  vrn: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values. (e.g. -)
]: nothing -> record<customerDetails: record<effectiveRegistrationDate: string>, flatRateScheme: record<frsCategory: string, startDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/organisations/vat/($vrn)/information")
  let extra_headers = {"Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
