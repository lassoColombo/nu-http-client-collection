# Auto-generated client for Business Source Adjustable Summary (MTD) v7.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/self-assessment-bsas-api/7.0/oas/resolved
# Auth: --token flag or $env.BUSINESS_SOURCE_ADJUSTABLE_SUMMARY_MTD_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_SOURCE_ADJUSTABLE_SUMMARY_MTD_TOKEN | default "" }
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

# Completers for enum parameters
def typeOfBusiness-completer [] { ["foreign-property" "foreign-property-fhl-eea" "self-employment" "uk-property" "uk-property-fhl"] }
def Accept-completer [] { ["application/vnd.hmrc.7.0+json"] }
def Content-Type-completer [] { ["application/json"] }
def zeroAdjustments-completer [] { ["true"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "individuals-self-assessment-adjustable-summary get" } } | get name | first)
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

# List Business Source Adjustable Summaries
#
# GET /individuals/self-assessment/adjustable-summary/{nino}/{taxYear}
export def "individuals-self-assessment-adjustable-summary get" [
  nino: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --typeOfBusiness: string@typeOfBusiness-completer # The type of business the summary calculation is for.  Limited to the following possible values for tax years 2024-25 and before:  - foreign-property-fhl-eea - foreign-property - uk-property - uk-property-fhl - self-employment  Limited to the following possible values for tax year 2025-26 onwards:  - foreign-property - uk-property - self-employment  (e.g. foreign-property)
  --businessId: string # An identifier for the business, unique to the customer. (e.g. XBIS12345678901)
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "typeOfBusiness" $typeOfBusiness "scalar") (serialize-qp "businessId" $businessId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/($taxYear)" $qp)
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Trigger a Business Source Adjustable Summary
#
# POST /individuals/self-assessment/adjustable-summary/{nino}/trigger
# --accountingPeriod shape: {startDate: string, endDate: string}
export def "individuals-self-assessment-adjustable-summary-trigger post" [
  nino: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --accountingPeriod: record # The duration of the business income source operations to be included in the tax year submission. The earliest tax year to which the accounting period can be assigned is 2019-20 for self-employment and UK property, and for foreign property, it is 2021-22.  Note: <b>Accounting period start and end dates should not be displayed to users of your software.</b> — shape: {startDate: string, endDate: string}
  --typeOfBusiness: string@typeOfBusiness-completer # The type of business the summary calculation is for.
  --businessId: string # An identifier for the business, unique to the customer. (e.g. XAIS12345678910)
]: any -> record<calculationId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/trigger")
  let body = {accountingPeriod: $accountingPeriod, typeOfBusiness: $typeOfBusiness, businessId: $businessId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Self-Employment Business Source Adjustable Summary
#
# GET /individuals/self-assessment/adjustable-summary/{nino}/self-employment/{calculationId}/{taxYear}
export def "individuals-self-assessment-adjustable-summary-self-employment get" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/self-employment/($calculationId)/($taxYear)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Self-Employment Accounting Adjustments
#
# POST /individuals/self-assessment/adjustable-summary/{nino}/self-employment/{calculationId}/adjust/{taxYear}
# --income shape: {turnover?: float, other?: float}
# --expenses shape: {costOfGoods?: float, paymentsToSubcontractors?: float, wagesAndStaffCosts?: float, carVanTravelExpenses?: float, premisesRunningCosts?: float, maintenanceCosts?: float, adminCosts?: float, interestOnBankOtherLoans?: float, financeCharges?: float, irrecoverableDebts?: float, professionalFees?: float, depreciation?: float, otherExpenses?: float, advertisingCosts?: float, businessEntertainmentCosts?: float, consolidatedExpenses?: float}
# --additions shape: {costOfGoodsDisallowable?: float, paymentsToSubcontractorsDisallowable?: float, wagesAndStaffCostsDisallowable?: float, carVanTravelExpensesDisallowable?: float, premisesRunningCostsDisallowable?: float, maintenanceCostsDisallowable?: float, adminCostsDisallowable?: float, interestOnBankOtherLoansDisallowable?: float, financeChargesDisallowable?: float, irrecoverableDebtsDisallowable?: float, professionalFeesDisallowable?: float, depreciationDisallowable?: float, otherExpensesDisallowable?: float, advertisingCostsDisallowable?: float, businessEntertainmentCostsDisallowable?: float}
export def "individuals-self-assessment-adjustable-summary-self-employment-adjust post" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --income: record # Object containing the adjustments to income values. — shape: {turnover?: float, other?: float}
  --expenses: record # Object containing the adjustments to expenses values. — shape: {costOfGoods?: float, paymentsToSubcontractors?: float, wagesAndStaffCosts?: float, carVanTravelExpenses?: float, premisesRunningCosts?: float, maintenanceCosts?: float, adminCosts?: float, interestOnBankOtherLoans?: float, financeCharges?: float, irrecoverableDebts?: float, professionalFees?: float, depreciation?: float, otherExpenses?: float, advertisingCosts?: float, businessEntertainmentCosts?: float, consolidatedExpenses?: float}
  --additions: record # An object containing the adjustments to additions values. — shape: {costOfGoodsDisallowable?: float, paymentsToSubcontractorsDisallowable?: float, wagesAndStaffCostsDisallowable?: float, carVanTravelExpensesDisallowable?: float, premisesRunningCostsDisallowable?: float, maintenanceCostsDisallowable?: float, adminCostsDisallowable?: float, interestOnBankOtherLoansDisallowable?: float, financeChargesDisallowable?: float, irrecoverableDebtsDisallowable?: float, professionalFeesDisallowable?: float, depreciationDisallowable?: float, otherExpensesDisallowable?: float, advertisingCostsDisallowable?: float, businessEntertainmentCostsDisallowable?: float}
  --zeroAdjustments: string@bool-completer # Indicates zero adjustments for all income, expenses and additions. The value can only be set to true.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/self-employment/($calculationId)/adjust/($taxYear)")
  let body = {income: $income, expenses: $expenses, additions: $additions, zeroAdjustments: $zeroAdjustments} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a UK Property Business Source Adjustable Summary
#
# GET /individuals/self-assessment/adjustable-summary/{nino}/uk-property/{calculationId}/{taxYear}
export def "individuals-self-assessment-adjustable-summary-uk-property get" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/uk-property/($calculationId)/($taxYear)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit UK Property Accounting Adjustments
#
# POST /individuals/self-assessment/adjustable-summary/{nino}/uk-property/{calculationId}/adjust/{taxYear}
# --ukProperty shape: {income?: record, expenses?: record}
# --furnishedHolidayLet shape: {income?: record, expenses?: record}
export def "individuals-self-assessment-adjustable-summary-uk-property-adjust post" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --ukProperty: record # Object holding UK Property adjustments. — shape: {income?: record, expenses?: record}
  --furnishedHolidayLet: record # Object holding FHL adjustments. — shape: {income?: record, expenses?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/uk-property/($calculationId)/adjust/($taxYear)")
  let body = {ukProperty: $ukProperty, furnishedHolidayLet: $furnishedHolidayLet} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve a Foreign Property Business Source Adjustable Summary
#
# GET /individuals/self-assessment/adjustable-summary/{nino}/foreign-property/{calculationId}/{taxYear}
export def "individuals-self-assessment-adjustable-summary-foreign-property get" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/foreign-property/($calculationId)/($taxYear)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Submit Foreign Property Accounting Adjustments
#
# POST /individuals/self-assessment/adjustable-summary/{nino}/foreign-property/{calculationId}/adjust/{taxYear}
# --foreignProperty item shape: {countryCode: string, income?: record, expenses?: record}
# --foreignFhlEea shape: {income?: record, expenses?: record}
export def "individuals-self-assessment-adjustable-summary-foreign-property-adjust post" [
  nino: string
  calculationId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Content-Type: string@Content-Type-completer # Specifies the format of the request body, which must be JSON.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  --foreignProperty: list # Array containing foreign Non-FHL adjustments. — item shape: {countryCode: string, income?: record, expenses?: record}
  --foreignFhlEea: record # Object holding FHL EEA adjustments. — shape: {income?: record, expenses?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/self-assessment/adjustable-summary/($nino)/foreign-property/($calculationId)/adjust/($taxYear)")
  let body = {foreignProperty: $foreignProperty, foreignFhlEea: $foreignFhlEea} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Content-Type": $Content_Type, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}
