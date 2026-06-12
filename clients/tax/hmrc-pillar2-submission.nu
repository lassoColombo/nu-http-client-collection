# Auto-generated client for Pillar 2 API v0.226.0
# Source: https://developer.service.hmrc.gov.uk/api-documentation/docs/api/service/pillar2-submission-api/1.0/oas/resolved
# Auth: --token flag or $env.PILLAR_2_API_TOKEN

const BASE_URL = "https://test-api.service.hmrc.gov.uk"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PILLAR_2_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://test-api.service.hmrc.gov.uk" "https://api.service.hmrc.gov.uk"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "organisations-pillar-two-setup-organisation get" } } | get name | first)
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

# Get Test Organisation
#
# GET /organisations/pillar-two/setup/organisation
# operationId: getTestOrganisation
export def "organisations-pillar-two-setup-organisation get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar 2 Id - Pattern: [A-Z0-9]{1,15}
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
]: nothing -> record<pillar2Id: string, organisation: record<orgDetails: record<domesticOnly: bool, organisationName: string, registrationDate: string>, accountingPeriod: record<startDate: string, endDate: string, underEnquiry: bool>, testData: record<accountActivityScenario: string>, lastUpdated: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/setup/organisation")
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update Test Organisation
#
# PUT /organisations/pillar-two/setup/organisation
# operationId: updateTestOrganisation
# --orgDetails shape: {domesticOnly: bool, organisationName: string, registrationDate: string}
# --accountingPeriod shape: {startDate: string, endDate: string, underEnquiry?: bool}
# --testData shape: {accountActivityScenario: "DTT_CHARGE"|"FULLY_PAID_CHARGE"|"FULLY_PAID_CHARGE_WITH_SPLIT_PAYMENTS"|"REPAYMENT_INTEREST"|"DTT_DETERMINATION"|"DTT_IIR_UTPR"|"ACCRUED_INTEREST"|"DTT_IIR_UTPR_INTEREST"|"DTT_IIR_UTPR_DETERMINATION"|"DTT_IIR_UTPR_DISCOVERY"|"DTT_IIR_UTPR_OVERPAID_CLAIM"|"UKTR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"ORN_GIR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"POTENTIAL_LOST_REVENUE_PENALTY"|"SCHEDULE_36_PENALTY"|"RECORD_KEEPING_PENALTY"|"REPAYMENT_CREDIT"|"INTEREST_REPAYMENT_CREDIT"|"COMBINED_REPAYMENT"}
export def "organisations-pillar-two-setup-organisation updateTestOrganisation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar 2 Id - Pattern: [A-Z0-9]{1,15}
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  orgDetails: record # Contains information about an organisation that is registered to Pillar 2. — shape: {domesticOnly: bool, organisationName: string, registrationDate: string}
  accountingPeriod: record # The period in which a group would be submitting their Pillar 2 returns to HMRC. This period of time varies amongst different businesses. It is effectively their "business year", and is expected to be the same as their accounting period with Pillar 2. — shape: {startDate: string, endDate: string, underEnquiry?: bool}
  --testData: record # shape: {accountActivityScenario: "DTT_CHARGE"|"FULLY_PAID_CHARGE"|"FULLY_PAID_CHARGE_WITH_SPLIT_PAYMENTS"|"REPAYMENT_INTEREST"|"DTT_DETERMINATION"|"DTT_IIR_UTPR"|"ACCRUED_INTEREST"|"DTT_IIR_UTPR_INTEREST"|"DTT_IIR_UTPR_DETERMINATION"|"DTT_IIR_UTPR_DISCOVERY"|"DTT_IIR_UTPR_OVERPAID_CLAIM"|"UKTR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"ORN_GIR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"POTENTIAL_LOST_REVENUE_PENALTY"|"SCHEDULE_36_PENALTY"|"RECORD_KEEPING_PENALTY"|"REPAYMENT_CREDIT"|"INTEREST_REPAYMENT_CREDIT"|"COMBINED_REPAYMENT"}
]: any -> record<pillar2Id: string, organisation: record<orgDetails: record<domesticOnly: bool, organisationName: string, registrationDate: string>, accountingPeriod: record<startDate: string, endDate: string, underEnquiry: bool>, testData: record<accountActivityScenario: string>, lastUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/setup/organisation")
  let body = {orgDetails: $orgDetails, accountingPeriod: $accountingPeriod, testData: $testData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create Test Organisation
#
# POST /organisations/pillar-two/setup/organisation
# operationId: createTestOrganisation
# --orgDetails shape: {domesticOnly: bool, organisationName: string, registrationDate: string}
# --accountingPeriod shape: {startDate: string, endDate: string, underEnquiry?: bool}
# --testData shape: {accountActivityScenario: "DTT_CHARGE"|"FULLY_PAID_CHARGE"|"FULLY_PAID_CHARGE_WITH_SPLIT_PAYMENTS"|"REPAYMENT_INTEREST"|"DTT_DETERMINATION"|"DTT_IIR_UTPR"|"ACCRUED_INTEREST"|"DTT_IIR_UTPR_INTEREST"|"DTT_IIR_UTPR_DETERMINATION"|"DTT_IIR_UTPR_DISCOVERY"|"DTT_IIR_UTPR_OVERPAID_CLAIM"|"UKTR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"ORN_GIR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"POTENTIAL_LOST_REVENUE_PENALTY"|"SCHEDULE_36_PENALTY"|"RECORD_KEEPING_PENALTY"|"REPAYMENT_CREDIT"|"INTEREST_REPAYMENT_CREDIT"|"COMBINED_REPAYMENT"}
export def "organisations-pillar-two-setup-organisation createTestOrganisation" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar 2 Id - Pattern: [A-Z0-9]{1,15}
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  orgDetails: record # Contains information about an organisation that is registered to Pillar 2. — shape: {domesticOnly: bool, organisationName: string, registrationDate: string}
  accountingPeriod: record # The period in which a group would be submitting their Pillar 2 returns to HMRC. This period of time varies amongst different businesses. It is effectively their "business year", and is expected to be the same as their accounting period with Pillar 2. — shape: {startDate: string, endDate: string, underEnquiry?: bool}
  --testData: record # shape: {accountActivityScenario: "DTT_CHARGE"|"FULLY_PAID_CHARGE"|"FULLY_PAID_CHARGE_WITH_SPLIT_PAYMENTS"|"REPAYMENT_INTEREST"|"DTT_DETERMINATION"|"DTT_IIR_UTPR"|"ACCRUED_INTEREST"|"DTT_IIR_UTPR_INTEREST"|"DTT_IIR_UTPR_DETERMINATION"|"DTT_IIR_UTPR_DISCOVERY"|"DTT_IIR_UTPR_OVERPAID_CLAIM"|"UKTR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"ORN_GIR_DTT_UKTR_MTT_LATE_FILING_PENALTY"|"POTENTIAL_LOST_REVENUE_PENALTY"|"SCHEDULE_36_PENALTY"|"RECORD_KEEPING_PENALTY"|"REPAYMENT_CREDIT"|"INTEREST_REPAYMENT_CREDIT"|"COMBINED_REPAYMENT"}
]: any -> record<pillar2Id: string, organisation: record<orgDetails: record<domesticOnly: bool, organisationName: string, registrationDate: string>, accountingPeriod: record<startDate: string, endDate: string, underEnquiry: bool>, testData: record<accountActivityScenario: string>, lastUpdated: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/setup/organisation")
  let body = {orgDetails: $orgDetails, accountingPeriod: $accountingPeriod, testData: $testData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Delete Test Organisation
#
# DELETE /organisations/pillar-two/setup/organisation
# operationId: deleteTestOrganisation
export def "organisations-pillar-two-setup-organisation delete" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar 2 Id - Pattern: [A-Z0-9]{1,15}
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/setup/organisation")
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Create A Test GloBE Information Return
#
# POST /organisations/pillar-two/setup/globe-information-return
# operationId: createGIR
export def "organisations-pillar-two-setup-globe-information-return createGIR" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar 2 Id - Pattern: [A-Z0-9]{1,15}
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  accountingPeriodFrom: string # format: date
  accountingPeriodTo: string # format: date
]: any -> record<processingDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/setup/globe-information-return")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Amend UK Tax Return
#
# PUT /organisations/pillar-two/uk-tax-return
# operationId: amendUKTR
# --liabilities shape: {electionDTTSingleMember: bool, electionUTPRSingleMember: bool, numberSubGroupDTT: int, numberSubGroupUTPR: int, totalLiability: float, totalLiabilityDTT: float, totalLiabilityIIR: float, totalLiabilityUTPR: float, liableEntities: list}
export def "organisations-pillar-two-uk-tax-return amendUKTR" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar2 ID for the submission
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  --accountingPeriodFrom: string # The calendar date upon which a business' accounting period begins. (format: date)
  --accountingPeriodTo: string # The calendar date upon which a business' accounting period ends. (format: date)
  --obligationMTT: oneof<nothing, bool> # Specifies whether a multinational group owes IIR or UTPR Pillar 2 tax. In the case where a group is 'domestic only', then the value must be `false`. Where a group is 'multinational', the value can be `true` or `false`.
  --electionUKGAAP: oneof<nothing, bool> # A means of calculating tax liability and profit. For domestic-only groups, the value can be `true` or `false`. For multinational groups, it must be `false`.
  --liabilities: record # A liability is a return for UKTR per accounting period which needs to be submitted (unless a BTN has been submitted). This is to be returned annually, and certain groups will need to submit this, whereas others will not. For the groups which do not need to submit a liability return, the value will be nil. For the groups which do need to submit an annual liability return, then the information found in the array will need to be populated. — shape: {electionDTTSingleMember: bool, electionUTPRSingleMember: bool, numberSubGroupDTT: int, numberSubGroupUTPR: int, totalLiability: float, totalLiabilityDTT: float, totalLiabilityIIR: float, totalLiabilityUTPR: float, liableEntities: list}
]: any -> record<processingDate: string, formBundleNumber: string, chargeReference: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/uk-tax-return")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo, obligationMTT: $obligationMTT, electionUKGAAP: $electionUKGAAP, liabilities: $liabilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit UK Tax Return
#
# POST /organisations/pillar-two/uk-tax-return
# operationId: submitUKTR
# --liabilities shape: {electionDTTSingleMember: bool, electionUTPRSingleMember: bool, numberSubGroupDTT: int, numberSubGroupUTPR: int, totalLiability: float, totalLiabilityDTT: float, totalLiabilityIIR: float, totalLiabilityUTPR: float, liableEntities: list}
export def "organisations-pillar-two-uk-tax-return submitUKTR" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar2 ID for the submission
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  --accountingPeriodFrom: string # The calendar date upon which a business' accounting period begins. (format: date)
  --accountingPeriodTo: string # The calendar date upon which a business' accounting period ends. (format: date)
  --obligationMTT: oneof<nothing, bool> # Specifies whether a multinational group owes IIR or UTPR Pillar 2 tax. In the case where a group is 'domestic only', then the value must be `false`. Where a group is 'multinational', the value can be `true` or `false`.
  --electionUKGAAP: oneof<nothing, bool> # A means of calculating tax liability and profit. For domestic-only groups, the value can be `true` or `false`. For multinational groups, it must be `false`.
  --liabilities: record # A liability is a return for UKTR per accounting period which needs to be submitted (unless a BTN has been submitted). This is to be returned annually, and certain groups will need to submit this, whereas others will not. For the groups which do not need to submit a liability return, the value will be nil. For the groups which do need to submit an annual liability return, then the information found in the array will need to be populated. — shape: {electionDTTSingleMember: bool, electionUTPRSingleMember: bool, numberSubGroupDTT: int, numberSubGroupUTPR: int, totalLiability: float, totalLiabilityDTT: float, totalLiabilityIIR: float, totalLiabilityUTPR: float, liableEntities: list}
]: any -> record<processingDate: string, formBundleNumber: string, chargeReference: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/uk-tax-return")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo, obligationMTT: $obligationMTT, electionUKGAAP: $electionUKGAAP, liabilities: $liabilities} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Below-Threshold Notification
#
# POST /organisations/pillar-two/below-threshold-notification
# operationId: submitBTN
export def "organisations-pillar-two-below-threshold-notification submitBTN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar2 ID for the submission
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  accountingPeriodFrom: string # The calendar date upon which a business' accounting period begins. (format: date)
  accountingPeriodTo: string # The calendar date upon which a business' accounting period ends. (format: date)
]: any -> record<processingDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/below-threshold-notification")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Obligations and Submissions
#
# GET /organisations/pillar-two/obligations-and-submissions
# operationId: retrieveData
export def "organisations-pillar-two-obligations-and-submissions retrieveData" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string
  --toDate: string
]: nothing -> record<processingDate: string, accountingPeriodDetails: table<startDate: string, endDate: string, dueDate: string, underEnquiry: bool, obligations: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organisations/pillar-two/obligations-and-submissions" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Retrieve Overseas Return Notification
#
# GET /organisations/pillar-two/overseas-return-notification
# operationId: retrieveORN
export def "organisations-pillar-two-overseas-return-notification retrieveORN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --accountingPeriodFrom: string # Period start date (format: date)
  --accountingPeriodTo: string # Period end date (format: date)
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar2 ID for the submission
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
]: nothing -> record<processingDate: string, accountingPeriodFrom: string, accountingPeriodTo: string, filedDateGIR: string, countryGIR: string, reportingEntityName: string, TIN: string, issuingCountryTIN: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "accountingPeriodFrom" $accountingPeriodFrom "scalar") (serialize-qp "accountingPeriodTo" $accountingPeriodTo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organisations/pillar-two/overseas-return-notification" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Amend Overseas Return Notification
#
# PUT /organisations/pillar-two/overseas-return-notification
# operationId: amendORN
export def "organisations-pillar-two-overseas-return-notification amendORN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pillar2-Id: string # Pillar2 ID for the submission.
  --Authorization: string # Bearer token for authentication
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  accountingPeriodFrom: string # The calendar date upon which a business' accounting period begins. (format: date)
  accountingPeriodTo: string # The calendar date upon which a business' accounting period ends. (format: date)
  filedDateGIR: string # The date upon which the GloBE Information Return (GIR) was filed or submitted. (format: date)
  countryGIR: string # The country in which the GloBE Information Return (GIR) was submitted.
  reportingEntityName: string # The name of the company that submitted the GloBE Information Return (GIR).
  TIN: string # The Tax Identification Number of the entity submitting the Overseas Return Notification.
  issuingCountryTIN: string # The country in which the Tax Identification Number was issued.
]: any -> record<processingDate: string, formBundleNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/overseas-return-notification")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo, filedDateGIR: $filedDateGIR, countryGIR: $countryGIR, reportingEntityName: $reportingEntityName, TIN: $TIN, issuingCountryTIN: $issuingCountryTIN} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pillar2-Id": $X_Pillar2_Id, "Authorization": $Authorization, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Submit Overseas Return Notification
#
# POST /organisations/pillar-two/overseas-return-notification
# operationId: submitORN
export def "organisations-pillar-two-overseas-return-notification submitORN" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --X-Pillar2-Id: string # Pillar2 ID for the submission.
  --Authorization: string # Bearer token for authentication
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
  accountingPeriodFrom: string # The calendar date upon which a business' accounting period begins. (format: date)
  accountingPeriodTo: string # The calendar date upon which a business' accounting period ends. (format: date)
  filedDateGIR: string # The date upon which the GloBE Information Return (GIR) was filed or submitted. (format: date)
  countryGIR: string # The country in which the GloBE Information Return (GIR) was submitted.
  reportingEntityName: string # The name of the company that submitted the GloBE Information Return (GIR).
  TIN: string # The Tax Identification Number of the entity submitting the Overseas Return Notification.
  issuingCountryTIN: string # The country in which the Tax Identification Number was issued.
]: any -> record<processingDate: string, formBundleNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/organisations/pillar-two/overseas-return-notification")
  let body = {accountingPeriodFrom: $accountingPeriodFrom, accountingPeriodTo: $accountingPeriodTo, filedDateGIR: $filedDateGIR, countryGIR: $countryGIR, reportingEntityName: $reportingEntityName, TIN: $TIN, issuingCountryTIN: $issuingCountryTIN} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Pillar2-Id": $X_Pillar2_Id, "Authorization": $Authorization, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Retrieve Account Activity
#
# GET /organisations/pillar-two/account-activity
# operationId: retrieveAccountActivity
export def "organisations-pillar-two-account-activity retrieveAccountActivity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --fromDate: string # Start of period to retrieve activity from. (format: date)
  --toDate: string # End of period to retrieve activity from. (format: date)
  --Authorization: string # Bearer token for authentication
  --X-Pillar2-Id: string # Pillar2 ID to retrieve activity for.
  --Accept: string # Specifies the expected response format as versioned JSON from the HMRC API (v1.0). If not provided, it will default to application/vnd.hmrc.1.0+json. (e.g. application/vnd.hmrc.1.0+json)
]: nothing -> record<processingDate: string, transactionDetails: table<transactionType: string, transactionDesc: string, startDate: string, endDate: string, accruedInterest: float, chargeRefNo: string, transactionDate: string, dueDate: string, originalAmount: float, outstandingAmount: float, clearedAmount: float, standOverAmount: float, appealFlag: bool, clearingDetails: list>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fromDate" $fromDate "scalar") (serialize-qp "toDate" $toDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/organisations/pillar-two/account-activity" $qp)
  let extra_headers = {"Authorization": $Authorization, "X-Pillar2-Id": $X_Pillar2_Id, "Accept": $Accept} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
