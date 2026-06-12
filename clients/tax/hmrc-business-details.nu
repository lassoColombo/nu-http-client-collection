# Auto-generated client for Business Details (MTD) v2.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/business-details-api/2.0/oas/resolved
# Auth: --token flag or $env.BUSINESS_DETAILS_MTD_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o BUSINESS_DETAILS_MTD_TOKEN | default "" }
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

def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def Accept-completer [] { ["application/vnd.hmrc.2.0+json"] }
def quarterlyPeriodType-completer [] { ["calendar" "standard"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "individuals-business-details-list get" } } | get name | first)
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

# List All Businesses
#
# GET /individuals/business/details/{nino}/list
export def "individuals-business-details-list get" [
  nino: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<listOfBusinesses: table<typeOfBusiness: string, businessId: string, tradingName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/list")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Business Details
#
# GET /individuals/business/details/{nino}/{businessId}
export def "individuals-business-details get" [
  nino: string
  businessId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<businessId: string, typeOfBusiness: string, tradingName: string, yearOfMigration: string, firstAccountingPeriodStartDate: string, firstAccountingPeriodEndDate: string, latencyDetails: record<latencyEndDate: string, taxYear1: string, latencyIndicator1: string, taxYear2: string, latencyIndicator2: string>, quarterlyTypeChoice: record<quarterlyPeriodType: string, taxYearOfChoice: string>, accountingPeriods: table<start: string, end: string>, commencementDate: string, cessationDate: string, businessAddressLineOne: string, businessAddressLineTwo: string, businessAddressLineThree: string, businessAddressLineFour: string, businessAddressPostcode: string, businessAddressCountryCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create and Amend Quarterly Period Type for a Business
#
# PUT /individuals/business/details/{nino}/{businessId}/{taxYear}
export def "individuals-business-details put" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
  quarterlyPeriodType: string@quarterlyPeriodType-completer # The quarterly period type that is being set for the business id. (e.g. standard)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)")
  let body = {quarterlyPeriodType: $quarterlyPeriodType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# GET /individuals/business/details/{nino}/{businessId}/{taxYear}/accounting-type
export def "individuals-business-details-accounting-type get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/accounting-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /individuals/business/details/{nino}/{businessId}/{taxYear}/accounting-type
export def "individuals-business-details-accounting-type put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/accounting-type")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /individuals/business/details/{nino}/{businessId}/{taxYear}/periods-of-account
export def "individuals-business-details-periods-of-account get" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/periods-of-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# PUT /individuals/business/details/{nino}/{businessId}/{taxYear}/periods-of-account
export def "individuals-business-details-periods-of-account put" [
  nino: any
  businessId: any
  taxYear: any
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/periods-of-account")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Late Accounting Date Rule Election
#
# GET /individuals/business/details/{nino}/{businessId}/{taxYear}/late-accounting-date-rule-election
export def "individuals-business-details-late-accounting-date-rule-election get" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *read:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> record<disapply: bool, eligible: bool, taxYearOfElection: string, taxYearElectionExpires: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/late-accounting-date-rule-election")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Disapply Late Accounting Date Rule
#
# POST /individuals/business/details/{nino}/{businessId}/{taxYear}/late-accounting-date-rule-election/disapply
export def "individuals-business-details-late-accounting-date-rule-election-disapply post" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/late-accounting-date-rule-election/disapply")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Withdraw Late Accounting Date Rule
#
# DELETE /individuals/business/details/{nino}/{businessId}/{taxYear}/late-accounting-date-rule-election/withdraw
export def "individuals-business-details-late-accounting-date-rule-election-withdraw delete" [
  nino: string
  businessId: string
  taxYear: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Accept: string@Accept-completer # Specifies the response format and the version of the API to be used.
  --Authorization: string # An OAuth 2.0 Bearer Token with the *write:self-assessment* scope.  (e.g. Bearer bb7fed3fe10dd235a2ccda3d50fb)
  --Gov-Test-Scenario: string # Only in sandbox environment. See Test Data table for all header values.  (e.g. -)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/individuals/business/details/($nino)/($businessId)/($taxYear)/late-accounting-date-rule-election/withdraw")
  let extra_headers = {"Accept": $Accept, "Authorization": $Authorization, "Gov-Test-Scenario": $Gov_Test_Scenario} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
