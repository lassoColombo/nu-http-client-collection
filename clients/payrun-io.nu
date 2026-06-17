# Auto-generated client for PayRun.IO v22.23.10.42
# Source: https://api.apis.guru/v2/specs/payrun.io/22.23.10.42/openapi.json
# Auth: --token flag or $env.PAYRUN_IO_TOKEN

const BASE_URL = "https://api.test.payrun.io"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYRUN_IO_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
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

def base-url-completer [] { ["https://api.test.payrun.io"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "employer delete" } } | get name | first)
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

# Delete an Employer
#
# DELETE /Employer/{EmployerId}
# operationId: DeleteEmployer
export def "employer delete" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer
#
# GET /Employer/{EmployerId}
# operationId: GetEmployer
export def "employer list" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the employer
#
# PATCH /Employer/{EmployerId}
# operationId: PatchEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
export def "employer update-by-EmployerId" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}"))
  let body = {"Employer": $employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the Employer
#
# PUT /Employer/{EmployerId}
# operationId: PutEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
export def "employer update-by-EmployerId-1" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}"))
  let body = {"Employer": $employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an CIS line type
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: DeleteCisLineType
export def "employer-cis-line-type delete" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line type from employer
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: GetCisLineTypeFromEmployer
export def "employer-cis-line-type get-cis-line-type-from" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the CIS line type
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: PutCisLineTypeIntoEmployer
# --CisLineType shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
export def "employer-cis-line-type update-cis-line-type-into" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}"))
  let body = {"CisLineType": $cis_line_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete CIS line type tag
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: DeleteCisLineTypeTag
export def "employer-cis-line-type-tag delete" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line type tag
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: GetTagFromCisLineType
export def "employer-cis-line-type-tag get-tag-from" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS line type tag
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: PutCisLineTypeTag
export def "employer-cis-line-type-tag update" [
  employer_id: string
  cis_line_type_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS line type
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tags
# operationId: GetTagsFromCisLineType
export def "employer-cis-line-type-tags get-tags-from" [
  employer_id: string
  cis_line_type_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_line_type_id: $cis_line_type_id} | format pattern "/Employer/{employer_id}/CisLineType/{cis_line_type_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line types from employer.
#
# GET /Employer/{EmployerId}/CisLineTypes
# operationId: GetCisLineTypesFromEmployer
export def "employer-cis-line-types get-cis-line-types-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/CisLineTypes"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new CIS line type
#
# POST /Employer/{EmployerId}/CisLineTypes
# operationId: PostCisLineTypeIntoEmployer
# --CisLineType shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
export def "employer-cis-line-types create-cis-line-type-into" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --cis-line-type: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/CisLineTypes"))
  let body = {"CisLineType": $cis_line_type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CIS line types with tag
#
# GET /Employer/{EmployerId}/CisLineTypes/Tag/{TagId}
# operationId: GetCisLineTypesWithTag
export def "employer-cis-line-types-tag get-cis-line-types-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/CisLineTypes/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS line type tags
#
# GET /Employer/{EmployerId}/CisLineTypes/Tags
# operationId: GetAllCisLineTypeTags
export def "employer-cis-line-types-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/CisLineTypes/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the CIS transaction
#
# DELETE /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: DeleteCisTransaction
export def "employer-cis-transaction delete" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_transaction_id: $cis_transaction_id} | format pattern "/Employer/{employer_id}/CisTransaction/{cis_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS transaction
#
# GET /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: GetCisTransactionFromEmployer
export def "employer-cis-transaction get-cis-transaction-from" [
  employer_id: string
  cis_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisTransaction: record<CisMessageType: string, EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, cis_transaction_id: $cis_transaction_id} | format pattern "/Employer/{employer_id}/CisTransaction/{cis_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS transactions for the employer
#
# GET /Employer/{EmployerId}/CisTransactions
# operationId: GetCisTransactionsFromEmployer
export def "employer-cis-transactions get-cis-transactions-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/CisTransactions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the DPS message
#
# DELETE /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: DeleteDpsMessage
export def "employer-dps-message delete" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, dps_message_id: $dps_message_id} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the DPS message
#
# GET /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: GetDpsMessageFromEmployer
export def "employer-dps-message get-dps-message-from" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, dps_message_id: $dps_message_id} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the DPS message
#
# PATCH /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PatchDpsMessage
export def "employer-dps-message update-by-EmployerId-DpsMessageId" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, dps_message_id: $dps_message_id} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts the DPS message
#
# PUT /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PutDpsMessage
export def "employer-dps-message update-by-EmployerId-DpsMessageId-1" [
  employer_id: string
  dps_message_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, dps_message_id: $dps_message_id} | format pattern "/Employer/{employer_id}/DpsMessage/{dps_message_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the DPS messages
#
# GET /Employer/{EmployerId}/DpsMessages
# operationId: GetDpsMessagesFromEmployer
export def "employer-dps-messages get-dps-messages-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/DpsMessages"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Posta the DPS message
#
# POST /Employer/{EmployerId}/DpsMessages
# operationId: PostDpsMessage
export def "employer-dps-messages create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/DpsMessages"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: DeleteEmployee
export def "employer-employee delete" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: GetEmployeeFromEmployer
export def "employer-employee get-employee-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the employee
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: PatchEmployee
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
export def "employer-employee update" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}"))
  let body = {"Employee": $employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the Employee
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: PutEmployeeIntoEmployer
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
export def "employer-employee update-employee-into" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}"))
  let body = {"Employee": $employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete auto enrolment assessment
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: DeleteAEAssessment
export def "employer-employee-ae-assessment delete-e" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto enrolment assessment
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: GetAEAssessmentFromEmployee
export def "employer-employee-ae-assessment get-e-assessment-from" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert new auto enrolment assessment
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: PutNewAEAssessment
# --AEAssessment shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
export def "employer-employee-ae-assessment update-new" [
  employer_id: string
  employee_id: string
  ae_assessment_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
]: any -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, ae_assessment_id: $ae_assessment_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessment/{ae_assessment_id}"))
  let body = {"AEAssessment": $ae_assessment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# operationId: GetAEAssessmentsFromEmployee
export def "employer-employee-ae-assessments get-e-assessments-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessments"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert new auto enrolment assessment
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# operationId: PostNewAEAssessment
# --AEAssessment shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
export def "employer-employee-ae-assessments create-new" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ae-assessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/AEAssessments"))
  let body = {"AEAssessment": $ae_assessment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get links to all commentaries for the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentaries
# operationId: GetCommentariesFromEmployee
export def "employer-employee-commentaries get-commentaries-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Commentaries"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commentary from employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentary/{CommentaryId}
# operationId: GetCommentaryFromEmployee
export def "employer-employee-commentary get-commentary-from" [
  employer_id: string
  employee_id: string
  commentary_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, commentary_id: $commentary_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Commentary/{commentary_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/JournalLines
# operationId: GetJournalLinesFromEmployee
export def "employer-employee-journal-lines get-journal-lines-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/JournalLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay instruction
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: DeletePayInstruction
export def "employer-employee-pay-instruction delete" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay instruction from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: GetPayInstructionFromEmployee
export def "employer-employee-pay-instruction get-pay-instruction-from" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sparse Update of a Pay Instruction
#
# PATCH /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: PatchPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "employer-employee-pay-instruction update-by-EmployerId-EmployeeId-PayInstructionId" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}"))
  let body = {"PayInstruction": $pay_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update a Pay Instruction
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: PutPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "employer-employee-pay-instruction update-by-EmployerId-EmployeeId-PayInstructionId-1" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}"))
  let body = {"PayInstruction": $pay_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pay instruction tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: DeletePayInstructionTag
export def "employer-employee-pay-instruction-tag delete" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay instruction tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: GetTagFromPayInstruction
export def "employer-employee-pay-instruction-tag get-tag-from" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay instruction tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: PutPayInstructionTag
export def "employer-employee-pay-instruction-tag update" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the pay instruction
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tags
# operationId: GetTagsFromPayInstruction
export def "employer-employee-pay-instruction-tags get-tags-from" [
  employer_id: string
  employee_id: string
  pay_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_instruction_id: $pay_instruction_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstruction/{pay_instruction_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay instructions from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# operationId: GetPayInstructionsFromEmployee
export def "employer-employee-pay-instructions get-pay-instructions-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Pay Instruction
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# operationId: PostPayInstruction
# --PayInstruction shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
export def "employer-employee-pay-instructions create" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-instruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions"))
  let body = {"PayInstruction": $pay_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay instructions with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tag/{TagId}
# operationId: GetPayInstructionsWithTag
export def "employer-employee-pay-instructions-tag get-pay-instructions-with" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay instruction tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tags
# operationId: GetAllPayInstructionTags
export def "employer-employee-pay-instructions-tags get-all" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayInstructions/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay line from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}
# operationId: GetPayLineFromEmployee
export def "employer-employee-pay-line get-pay-line-from" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayLine: record<Calculator: string, Description: string, Generated: string, PayCode: string, PayCodeType: string, PayRunSequence: int, PaymentDate: string, TaxPeriod: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay line tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: DeletePayLineTag
export def "employer-employee-pay-line-tag delete" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay line tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: GetTagFromPayLine
export def "employer-employee-pay-line-tag get-tag-from" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay line tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: PutPayLineTag
export def "employer-employee-pay-line-tag update" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the pay line
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tags
# operationId: GetTagsFromPayLine
export def "employer-employee-pay-line-tags get-tags-from" [
  employer_id: string
  employee_id: string
  pay_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, pay_line_id: $pay_line_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLine/{pay_line_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines
# operationId: GetPayLinesFromEmployee
export def "employer-employee-pay-lines get-pay-lines-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay lines with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tag/{TagId}
# operationId: GetPayLinesWithTag
export def "employer-employee-pay-lines-tag get-pay-lines-with" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay line tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tags
# operationId: GetAllPayLineTags
export def "employer-employee-pay-lines-tags get-all" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayLines/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay runs from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayRuns
# operationId: GetPayRunsFromEmployee
export def "employer-employee-pay-runs get-pay-runs-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/PayRuns"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: DeleteEmployeeRevisionByNumber
export def "employer-employee-revision delete" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employee by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: GetEmployeeRevisionByNumber
export def "employer-employee-revision get" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employee summary by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployeeRevisionSummaryByNumber
export def "employer-employee-revision-summary get" [
  employer_id: string
  employee_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revision/{revision_number}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revisions
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions
# operationId: GetEmployeeRevisions
export def "employer-employee-revisions get" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revision summaries
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions/Summary
# operationId: GetEmployeeRevisionSummaries
export def "employer-employee-revisions-summary get-employee-revision-summaries" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Revisions/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes employee secret
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: DeleteEmployeeSecret
export def "employer-employee-secret delete" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee secret
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: GetEmployeeSecret
export def "employer-employee-secret get" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employee secret
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: PutEmployeeSecret
export def "employer-employee-secret update" [
  employer_id: string
  employee_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee secret links
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: GetEmployeeSecrets
export def "employer-employee-secrets get" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secrets"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employee secret
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: PostEmployeeSecret
export def "employer-employee-secrets create" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Secrets"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summary from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Summary
# operationId: GetEmployeeSummaryFromEmployer
export def "employer-employee-summary get-employee-summary-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete employee tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: DeleteEmployeeTag
export def "employer-employee-tag delete" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: GetTagFromEmployee
export def "employer-employee-tag get-tag-from" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert employee tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: PutEmployeeTag
export def "employer-employee-tag update" [
  employer_id: string
  employee_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee revision tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployeeRevision
export def "employer-employee-tag get-tag-from-employee-revision" [
  employer_id: string
  employee_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, tag_id: $tag_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tag/{tag_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags
# operationId: GetTagsFromEmployee
export def "employer-employee-tags get-tags-from" [
  employer_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revision tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployeeRevision
export def "employer-employee-tags get-tags-from-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/Tags/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: DeleteEmployeeRevision
export def "employer-employee delete-employee-revision" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: GetEmployeeByEffectiveDate
export def "employer-employee get" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summary by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}/Summary
# operationId: GetEmployeeSummaryByEffectiveDate
export def "employer-employee-summary get" [
  employer_id: string
  employee_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, employee_id: $employee_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employee/{employee_id}/{effective_date}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from employer.
#
# GET /Employer/{EmployerId}/Employees
# operationId: GetEmployeesFromEmployer
export def "employer-employees get-employees-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Employees"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Employee
#
# POST /Employer/{EmployerId}/Employees
# operationId: PostEmployeeIntoEmployer
# --Employee shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
export def "employer-employees create-employee-into" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Employees"))
  let body = {"Employee": $employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get employee summaries from employer.
#
# GET /Employer/{EmployerId}/Employees/Summary
# operationId: GetEmployeeSummariesFromEmployer
export def "employer-employees-summary get-employee-summaries-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Employees/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees with tag
#
# GET /Employer/{EmployerId}/Employees/Tag/{TagId}
# operationId: GetEmployeesWithTag
export def "employer-employees-tag get-employees-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Employees/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employees/Tags
# operationId: GetAllEmployeeTags
export def "employer-employees-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Employees/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}
# operationId: GetEmployeesByEffectiveDate
export def "employer-employees get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employees/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summaries from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}/Summary
# operationId: GetEmployeeSummariesByEffectiveDate
export def "employer-employees-summary get-employee-summaries" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Employees/{effective_date}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an holiday scheme
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: DeleteHolidayScheme
export def "employer-holiday-scheme delete" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme from employer
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: GetHolidaySchemeFromEmployer
export def "employer-holiday-scheme get-holiday-scheme-from" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the holiday scheme
#
# PATCH /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: PatchHolidayScheme
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "employer-holiday-scheme update" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}"))
  let body = {"HolidayScheme": $holiday_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the holiday scheme
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: PutHolidaySchemeIntoEmployer
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "employer-holiday-scheme update-holiday-scheme-into" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}"))
  let body = {"HolidayScheme": $holiday_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an HolidayScheme revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: DeleteHolidaySchemeRevisionByNumber
export def "employer-holiday-scheme-revision delete" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the holiday scheme revision by revision number
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: GetHolidaySchemeRevisionByNumber
export def "employer-holiday-scheme-revision get" [
  employer_id: string
  holiday_scheme_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme revisions
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revisions
# operationId: GetHolidaySchemeRevisions
export def "employer-holiday-scheme-revisions get" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete holiday scheme tag
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: DeleteHolidaySchemeTag
export def "employer-holiday-scheme-tag delete" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: GetTagFromHolidayScheme
export def "employer-holiday-scheme-tag get-tag-from" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert holiday scheme tag
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: PutHolidaySchemeTag
export def "employer-holiday-scheme-tag update" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme revision tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromHolidaySchemeRevision
export def "employer-holiday-scheme-tag get-tag-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, tag_id: $tag_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tag/{tag_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the holiday scheme
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags
# operationId: GetTagsFromHolidayScheme
export def "employer-holiday-scheme-tags get-tags-from" [
  employer_id: string
  holiday_scheme_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme revision tags
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromHolidaySchemeRevision
export def "employer-holiday-scheme-tags get-tags-from-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/Tags/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an holiday scheme revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: DeleteHolidaySchemeRevision
export def "employer-holiday-scheme delete-holiday-scheme-revision" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme by effective date.
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: GetHolidaySchemeByEffectiveDate
export def "employer-holiday-scheme get" [
  employer_id: string
  holiday_scheme_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, holiday_scheme_id: $holiday_scheme_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/HolidayScheme/{holiday_scheme_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday schemes from employer.
#
# GET /Employer/{EmployerId}/HolidaySchemes
# operationId: GetHolidaySchemesFromEmployer
export def "employer-holiday-schemes get-holiday-schemes-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/HolidaySchemes"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new holiday scheme
#
# POST /Employer/{EmployerId}/HolidaySchemes
# operationId: PostHolidaySchemeIntoEmployer
# --HolidayScheme shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
export def "employer-holiday-schemes create-holiday-scheme-into" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --holiday-scheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/HolidaySchemes"))
  let body = {"HolidayScheme": $holiday_scheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get holiday schemes with tag
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tag/{TagId}
# operationId: GetHolidaySchemesWithTag
export def "employer-holiday-schemes-tag get-holiday-schemes-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/HolidaySchemes/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme tags
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tags
# operationId: GetAllHolidaySchemeTags
export def "employer-holiday-schemes-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/HolidaySchemes/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday schemes from employer at a given effective date.
#
# GET /Employer/{EmployerId}/HolidaySchemes/{EffectiveDate}
# operationId: GetHolidaySchemesByEffectiveDate
export def "employer-holiday-schemes get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/HolidaySchemes/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Journal instruction
#
# DELETE /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstruction
export def "employer-journal-instruction delete" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_instruction_id: $journal_instruction_id} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified journal instruction from the employer
#
# GET /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionFromEmployer
export def "employer-journal-instruction get-journal-instruction-from" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_instruction_id: $journal_instruction_id} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Journal Instruction
#
# PUT /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstruction
export def "employer-journal-instruction update" [
  employer_id: string
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_instruction_id: $journal_instruction_id} | format pattern "/Employer/{employer_id}/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions from the specified employer
#
# GET /Employer/{EmployerId}/JournalInstructions
# operationId: GetJournalInstructionsFromEmployer
export def "employer-journal-instructions get-journal-instructions-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/JournalInstructions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Journal Instruction
#
# POST /Employer/{EmployerId}/JournalInstructions
# operationId: PostJournalInstruction
export def "employer-journal-instructions create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/JournalInstructions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified journal Line from the employer
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}
# operationId: GetJournalLineFromEmployer
export def "employer-journal-line get-journal-line-from" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalLine: record<Credit: float, Debit: float, Description: string, Employee: record<_href: string, _rel: string, _title: string>, Generated: string, Grouping: string, LedgerTarget: string, NomCode: string, PayFrequency: string, PayRun: record<_href: string, _rel: string, _title: string>, SubContractor: record<_href: string, _rel: string, _title: string>, SubNomCode: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_line_id: $journal_line_id} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete journal line tag
#
# DELETE /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: DeleteJournalLineTag
export def "employer-journal-line-tag delete" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get journal line tag
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: GetTagFromJournalLine
export def "employer-journal-line-tag get-tag-from" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert journal line tag
#
# PUT /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: PutJournalLineTag
export def "employer-journal-line-tag update" [
  employer_id: string
  journal_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_line_id: $journal_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from journal line
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tags
# operationId: GetTagsFromJournalLine
export def "employer-journal-line-tags get-tags-from" [
  employer_id: string
  journal_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, journal_line_id: $journal_line_id} | format pattern "/Employer/{employer_id}/JournalLine/{journal_line_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal Lines from the specified employer
#
# GET /Employer/{EmployerId}/JournalLines
# operationId: GetJournalLinesFromEmployer
export def "employer-journal-lines get-journal-lines-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/JournalLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged journal lines
#
# GET /Employer/{EmployerId}/JournalLines/Tag/{TagId}
# operationId: GetAllJournalLinesWithTag
export def "employer-journal-lines-tag get-all-journal-lines-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/JournalLines/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all journal line tags
#
# GET /Employer/{EmployerId}/JournalLines/Tags
# operationId: GetAllJournalLineTags
export def "employer-journal-lines-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/JournalLines/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the nominal codes
#
# DELETE /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: DeleteNominalCode
export def "employer-nominal-code delete" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, nominal_code_id: $nominal_code_id} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: GetNominalCodeFromEmployer
export def "employer-nominal-code get-nominal-code-from" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<NominalCode: record<Description: string, Key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, nominal_code_id: $nominal_code_id} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert nominal code
#
# PUT /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: PutNominalCode
# --NominalCode shape: {Description?: string, Key?: string}
export def "employer-nominal-code update" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> record<NominalCode: record<Description: string, Key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, nominal_code_id: $nominal_code_id} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}"))
  let body = {"NominalCode": $nominal_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the pay codes by nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}/PayCodes
# operationId: GetPayCodesFromNominalCode
export def "employer-nominal-code-pay-codes get-pay-codes-from" [
  employer_id: string
  nominal_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, nominal_code_id: $nominal_code_id} | format pattern "/Employer/{employer_id}/NominalCode/{nominal_code_id}/PayCodes"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the nominal codes
#
# GET /Employer/{EmployerId}/NominalCodes
# operationId: GetNominalCodesFromEmployer
export def "employer-nominal-codes get-nominal-codes-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/NominalCodes"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert nominal code
#
# POST /Employer/{EmployerId}/NominalCodes
# operationId: PostNominalCode
# --NominalCode shape: {Description?: string, Key?: string}
export def "employer-nominal-codes create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --nominal-code: record # shape: {Description?: string, Key?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/NominalCodes"))
  let body = {"NominalCode": $nominal_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a pay code
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: DeletePayCode
export def "employer-pay-code delete" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay code from the employer
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: GetPayCodeFromEmployer
export def "employer-pay-code get-pay-code-from" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the pay code
#
# PATCH /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: PatchPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "employer-pay-code update-by-EmployerId-PayCodeId" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}"))
  let body = {"PayCode": $pay_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates a pay code
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: PutPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "employer-pay-code update-by-EmployerId-PayCodeId-1" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}"))
  let body = {"PayCode": $pay_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an PayCode revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: DeletePayCodeRevisionByNumber
export def "employer-pay-code-revision delete" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay code by revision number
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: GetPayCodeRevisionByNumber
export def "employer-pay-code-revision get" [
  employer_id: string
  pay_code_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all revisions of the Pay Code
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revisions
# operationId: GetPayCodeRevisions
export def "employer-pay-code-revisions get" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay code tag
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: DeletePayCodeTag
export def "employer-pay-code-tag delete" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay code tag
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: GetTagFromPayCode
export def "employer-pay-code-tag get-tag-from" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay code tag
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: PutPayCodeTag
export def "employer-pay-code-tag update" [
  employer_id: string
  pay_code_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tags
# operationId: GetTagsFromPayCode
export def "employer-pay-code-tags get-tags-from" [
  employer_id: string
  pay_code_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay code revision
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: DeletePayCodeRevision
export def "employer-pay-code delete-pay-code-revision" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets pay code for specified date
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: GetPayCodeByEffectiveDate
export def "employer-pay-code get" [
  employer_id: string
  pay_code_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_code_id: $pay_code_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/PayCode/{pay_code_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay codes from the employer
#
# GET /Employer/{EmployerId}/PayCodes
# operationId: GetPayCodesFromEmployer
export def "employer-pay-codes get-pay-codes-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PayCodes"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new pay code
#
# POST /Employer/{EmployerId}/PayCodes
# operationId: PostPayCode
# --PayCode shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
export def "employer-pay-codes create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-code: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PayCodes"))
  let body = {"PayCode": $pay_code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay codes with tag
#
# GET /Employer/{EmployerId}/PayCodes/Tag/{TagId}
# operationId: GetPayCodesWithTag
export def "employer-pay-codes-tag get-pay-codes-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PayCodes/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCodes/Tags
# operationId: GetAllPayCodeTags
export def "employer-pay-codes-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PayCodes/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all pay codes for specified date
#
# GET /Employer/{EmployerId}/PayCodes/{EffectiveDate}
# operationId: GetPayCodesByEffectiveDate
export def "employer-pay-codes get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/PayCodes/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay schedule
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: DeletePaySchedule
export def "employer-pay-schedule delete" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay schedule from the employer
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: GetPayScheduleFromEmployer
export def "employer-pay-schedule get-pay-schedule-from" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a pay schedule
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: PutPaySchedule
# --PaySchedule shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
export def "employer-pay-schedule update" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}"))
  let body = {"PaySchedule": $pay_schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all employees revisions from a pay schedule.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees
# operationId: GetEmployeesFromPaySchedule
export def "employer-pay-schedule-employees get-employees-from" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Employees"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from a pay schedule on effective date.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees/{EffectiveDate}
# operationId: GetEmployeesFromPayScheduleOnEffectiveDate
export def "employer-pay-schedule-employees get-employees-from-pay-schedule-on-effective-date" [
  employer_id: string
  pay_schedule_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Employees/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay run
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: DeletePayRun
export def "employer-pay-schedule-pay-run delete" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay run from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: GetPayRunFromPaySchedule
export def "employer-pay-schedule-pay-run get-pay-run-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayRun: record<Executed: string, IsSupplementary: bool, PayFrequency: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentDate: string, PeriodEnd: string, PeriodStart: string, ProceedingPayRun: record<_href: string, _rel: string, _title: string>, Sequence: int, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/AEAssessments
# operationId: GetAEAssessmentsFromPayRun
export def "employer-pay-schedule-pay-run-ae-assessments get-e-assessments-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/AEAssessments"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to all commentaries for the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Commentaries
# operationId: GetCommentariesFromPayRun
export def "employer-pay-schedule-pay-run-commentaries get-commentaries-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Commentaries"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay run employee
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}
# operationId: DeletePayRunEmployee
export def "employer-pay-schedule-pay-run-employee delete" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employee/{employee_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commentary from payrun by specified employee.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}/Commentary
# operationId: GetCommentaryFromPayRunByEmployee
export def "employer-pay-schedule-pay-run-employee-commentary get-commentary-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, employee_id: $employee_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employee/{employee_id}/Commentary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from the pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employees
# operationId: GetEmployeesFromPayRun
export def "employer-pay-schedule-pay-run-employees get-employees-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Employees"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/JournalLines
# operationId: GetJournalLinesFromPayRun
export def "employer-pay-schedule-pay-run-journal-lines get-journal-lines-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/JournalLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/PayLines
# operationId: GetPayLinesFromPayRun
export def "employer-pay-schedule-pay-run-pay-lines get-pay-lines-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/PayLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the report lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/ReportLines
# operationId: GetReportLinesFromPayRun
export def "employer-pay-schedule-pay-run-report-lines get-report-lines-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/ReportLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay run tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: DeletePayRunTag
export def "employer-pay-schedule-pay-run-tag delete" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay run tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: GetTagFromPayRun
export def "employer-pay-schedule-pay-run-tag get-tag-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay run tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: PutPayRunTag
export def "employer-pay-schedule-pay-run-tag update" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tags
# operationId: GetTagsFromPayRun
export def "employer-pay-schedule-pay-run-tags get-tags-from" [
  employer_id: string
  pay_schedule_id: string
  pay_run_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, pay_run_id: $pay_run_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRun/{pay_run_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay runs from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns
# operationId: GetPayRunsFromPaySchedule
export def "employer-pay-schedule-pay-runs get-pay-runs-from" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay runs with tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tag/{TagId}
# operationId: GetPayRunsWithTag
export def "employer-pay-schedule-pay-runs-tag get-pay-runs-with" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tags
# operationId: GetAllPayRunTags
export def "employer-pay-schedule-pay-runs-tags get-all" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/PayRuns/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay schedule tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: DeletePayScheduleTag
export def "employer-pay-schedule-tag delete" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay schedule tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: GetTagFromPaySchedule
export def "employer-pay-schedule-tag get-tag-from" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay schedule tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: PutPayScheduleTag
export def "employer-pay-schedule-tag update" [
  employer_id: string
  pay_schedule_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tags
# operationId: GetTagsFromPaySchedule
export def "employer-pay-schedule-tags get-tags-from" [
  employer_id: string
  pay_schedule_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pay_schedule_id: $pay_schedule_id} | format pattern "/Employer/{employer_id}/PaySchedule/{pay_schedule_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay schedule from the specified employer
#
# GET /Employer/{EmployerId}/PaySchedules
# operationId: GetPaySchedulesFromEmployer
export def "employer-pay-schedules get-pay-schedules-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PaySchedules"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new pay schedule
#
# POST /Employer/{EmployerId}/PaySchedules
# operationId: PostPaySchedule
# --PaySchedule shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
export def "employer-pay-schedules create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-schedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PaySchedules"))
  let body = {"PaySchedule": $pay_schedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay schedule with tag
#
# GET /Employer/{EmployerId}/PaySchedules/Tag/{TagId}
# operationId: GetPaySchedulesWithTag
export def "employer-pay-schedules-tag get-pay-schedules-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/PaySchedules/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedules/Tags
# operationId: GetAllPayScheduleTags
export def "employer-pay-schedules-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/PaySchedules/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Pension
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}
# operationId: DeletePension
export def "employer-pension delete" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id} | format pattern "/Employer/{employer_id}/Pension/{pension_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pension from employer
#
# GET /Employer/{EmployerId}/Pension/{PensionId}
# operationId: GetPensionFromEmployer
export def "employer-pension get-pension-from" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id} | format pattern "/Employer/{employer_id}/Pension/{pension_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the pension
#
# PATCH /Employer/{EmployerId}/Pension/{PensionId}
# operationId: PatchPension
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
export def "employer-pension update" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id} | format pattern "/Employer/{employer_id}/Pension/{pension_id}"))
  let body = {"Pension": $pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the Pension
#
# PUT /Employer/{EmployerId}/Pension/{PensionId}
# operationId: PutPensionIntoEmployer
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
export def "employer-pension update-pension-into" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id} | format pattern "/Employer/{employer_id}/Pension/{pension_id}"))
  let body = {"Pension": $pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Pension revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: DeletePensionRevisionByNumber
export def "employer-pension-revision delete" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pension by revision number
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: GetPensionRevisionByNumber
export def "employer-pension-revision get" [
  employer_id: string
  pension_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pension revisions
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revisions
# operationId: GetPensionRevisions
export def "employer-pension-revisions get" [
  employer_id: string
  pension_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Pension revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: DeletePensionRevision
export def "employer-pension delete-pension-revision" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pension by effective date.
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: GetPensionByEffectiveDate
export def "employer-pension get" [
  employer_id: string
  pension_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, pension_id: $pension_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Pension/{pension_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pensions from employer.
#
# GET /Employer/{EmployerId}/Pensions
# operationId: GetPensionsFromEmployer
export def "employer-pensions get-pensions-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Pensions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Pension
#
# POST /Employer/{EmployerId}/Pensions
# operationId: PostPensionIntoEmployer
# --Pension shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
export def "employer-pensions create-pension-into" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Pensions"))
  let body = {"Pension": $pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pensions from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Pensions/{EffectiveDate}
# operationId: GetPensionsByEffectiveDate
export def "employer-pensions get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Pensions/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified report line from the employer
#
# GET /Employer/{EmployerId}/ReportLine/{ReportLineId}
# operationId: GetReportLineFromEmployer
export def "employer-report-line get-report-line-from" [
  employer_id: string
  report_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportLine: record<Description: string, Generated: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, report_line_id: $report_line_id} | format pattern "/Employer/{employer_id}/ReportLine/{report_line_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the report lines from the specified employer
#
# GET /Employer/{EmployerId}/ReportLines
# operationId: GetReportLinesFromEmployer
export def "employer-report-lines get-report-lines-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/ReportLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a reporting instruction
#
# DELETE /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: DeleteReportingInstruction
export def "employer-reporting-instruction delete" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified reporting instruction from the employer
#
# GET /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: GetReportingInstructionFromEmployer
export def "employer-reporting-instruction get-reporting-instruction-from" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a reporting Instruction
#
# PUT /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: PutReportingInstruction
# --ReportingInstruction shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
export def "employer-reporting-instruction update" [
  employer_id: string
  reporting_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, reporting_instruction_id: $reporting_instruction_id} | format pattern "/Employer/{employer_id}/ReportingInstruction/{reporting_instruction_id}"))
  let body = {"ReportingInstruction": $reporting_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the reporting instructions from the specified employer
#
# GET /Employer/{EmployerId}/ReportingInstructions
# operationId: GetReportingInstructionsFromEmployer
export def "employer-reporting-instructions get-reporting-instructions-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/ReportingInstructions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Reporting Instruction
#
# POST /Employer/{EmployerId}/ReportingInstructions
# operationId: PostReportingInstruction
# --ReportingInstruction shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
export def "employer-reporting-instructions create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --reporting-instruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/ReportingInstructions"))
  let body = {"ReportingInstruction": $reporting_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Employer revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: DeleteEmployerRevisionByNumber
export def "employer-revision delete" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: GetEmployerRevisionByNumber
export def "employer-revision get" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer summary by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployerRevisionSummaryByNumber
export def "employer-revision-summary get" [
  employer_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/Revision/{revision_number}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer revisions
#
# GET /Employer/{EmployerId}/Revisions
# operationId: GetEmployerRevisions
export def "employer-revisions get" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer revision summaries
#
# GET /Employer/{EmployerId}/Revisions/Summary
# operationId: GetEmployerRevisionSummaries
export def "employer-revisions-summary get-employer-revision-summaries" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Revisions/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the RTI transaction
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: DeleteRtiTransaction
export def "employer-rti-transaction delete" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: GetRtiTransactionFromEmployer
export def "employer-rti-transaction get-rti-transaction-from" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI transaction summary
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Summary
# operationId: GetRtiTransactionSummaryFromEmployer
export def "employer-rti-transaction-summary get-rti-transaction-summary-from" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete RTI transaction tag
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: DeleteRtiTransactionTag
export def "employer-rti-transaction-tag delete" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get RTI transaction tag
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: GetTagFromRtiTransaction
export def "employer-rti-transaction-tag get-tag-from" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert RTI transaction tag
#
# PUT /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: PutRtiTransactionTag
export def "employer-rti-transaction-tag update" [
  employer_id: string
  rti_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tags
# operationId: GetTagsFromRtiTransaction
export def "employer-rti-transaction-tags get-tags-from" [
  employer_id: string
  rti_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, rti_transaction_id: $rti_transaction_id} | format pattern "/Employer/{employer_id}/RtiTransaction/{rti_transaction_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transactions for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions
# operationId: GetRtiTransactionsFromEmployer
export def "employer-rti-transactions get-rti-transactions-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/RtiTransactions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transaction summaries for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions/Summary
# operationId: GetRtiTransactionSummariesFromEmployer
export def "employer-rti-transactions-summary get-rti-transaction-summaries-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/RtiTransactions/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get RTI transactions with tag
#
# GET /Employer/{EmployerId}/RtiTransactions/Tag/{TagId}
# operationId: GetRtiTransactionsWithTag
export def "employer-rti-transactions-tag get-rti-transactions-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/RtiTransactions/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transaction tags
#
# GET /Employer/{EmployerId}/RtiTransactions/Tags
# operationId: GetAllRtiTransactionTags
export def "employer-rti-transactions-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/RtiTransactions/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes employer secret
#
# DELETE /Employer/{EmployerId}/Secret/{SecretId}
# operationId: DeleteEmployerSecret
export def "employer-secret delete" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer secret
#
# GET /Employer/{EmployerId}/Secret/{SecretId}
# operationId: GetEmployerSecret
export def "employer-secret get" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employer secret
#
# PUT /Employer/{EmployerId}/Secret/{SecretId}
# operationId: PutEmployerSecret
export def "employer-secret update" [
  employer_id: string
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, secret_id: $secret_id} | format pattern "/Employer/{employer_id}/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer secret links
#
# GET /Employer/{EmployerId}/Secrets
# operationId: GetEmployerSecrets
export def "employer-secrets get" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Secrets"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employer secret
#
# POST /Employer/{EmployerId}/Secrets
# operationId: PostEmployerSecret
export def "employer-secrets create" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Secrets"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an sub contractor
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: DeleteSubContractor
export def "employer-sub-contractor delete" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor from employer
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: GetSubContractorFromEmployer
export def "employer-sub-contractor get-sub-contractor-from" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the sub contractor
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: PatchSubContractor
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
export def "employer-sub-contractor update" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}"))
  let body = {"SubContractor": $sub_contractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the sub contractor
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: PutSubContractorIntoEmployer
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
export def "employer-sub-contractor update-sub-contractor-into" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}"))
  let body = {"SubContractor": $sub_contractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a CIS instruction
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: DeleteCisInstruction
export def "employer-sub-contractor-cis-instruction delete" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instruction from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: GetCisInstructionFromSubContractor
export def "employer-sub-contractor-cis-instruction get-cis-instruction-from" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the CIS instruction
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: PatchCisInstruction
export def "employer-sub-contractor-cis-instruction update" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the CIS instruction
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: PutCisInstructionIntoSubContractor
# --CisInstruction shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
export def "employer-sub-contractor-cis-instruction update-cis-instruction-into" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}"))
  let body = {"CisInstruction": $cis_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete CIS instruction tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: DeleteCisInstructionTag
export def "employer-sub-contractor-cis-instruction-tag delete" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instruction tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: GetTagFromCisInstruction
export def "employer-sub-contractor-cis-instruction-tag get-tag-from" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS instruction tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: PutCisInstructionTag
export def "employer-sub-contractor-cis-instruction-tag update" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS instruction
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tags
# operationId: GetTagsFromCisInstruction
export def "employer-sub-contractor-cis-instruction-tags get-tags-from" [
  employer_id: string
  sub_contractor_id: string
  cis_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_instruction_id: $cis_instruction_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstruction/{cis_instruction_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instructions from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# operationId: GetCisInstructionsFromSubContractor
export def "employer-sub-contractor-cis-instructions get-cis-instructions-from" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new CIS instruction
#
# POST /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# operationId: PostCisInstructionIntoSubContractor
# --CisInstruction shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
export def "employer-sub-contractor-cis-instructions create-cis-instruction-into" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --cis-instruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions"))
  let body = {"CisInstruction": $cis_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CIS instructions with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tag/{TagId}
# operationId: GetCisInstructionsWithTag
export def "employer-sub-contractor-cis-instructions-tag get-cis-instructions-with" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS instruction tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tags
# operationId: GetAllCisInstructionTags
export def "employer-sub-contractor-cis-instructions-tags get-all" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisInstructions/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a CIS line
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: DeleteCisLine
export def "employer-sub-contractor-cis-line delete" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: GetCisLineFromSubContractor
export def "employer-sub-contractor-cis-line get-cis-line-from" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisLine: record<CisDeduction: float, CisLineType: string, Description: string, Generated: string, GrossPay: float, NominalCodeKey: string, PayFrequency: string, TaxMonth: int, TaxPeriod: int, TaxTreatment: string, TaxYear: int, UOM: string, UnitRate: float, Units: float, VAT: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete CIS line tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: DeleteCisLineTag
export def "employer-sub-contractor-cis-line-tag delete" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: GetTagFromCisLine
export def "employer-sub-contractor-cis-line-tag get-tag-from" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS line tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: PutCisLineTag
export def "employer-sub-contractor-cis-line-tag update" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS line
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tags
# operationId: GetTagsFromCisLine
export def "employer-sub-contractor-cis-line-tags get-tags-from" [
  employer_id: string
  sub_contractor_id: string
  cis_line_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, cis_line_id: $cis_line_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLine/{cis_line_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS lines from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines
# operationId: GetCisLinesFromSubContractor
export def "employer-sub-contractor-cis-lines get-cis-lines-from" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS lines with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tag/{TagId}
# operationId: GetCisLinesWithTag
export def "employer-sub-contractor-cis-lines-tag get-cis-lines-with" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS line tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tags
# operationId: GetAllCisLineTags
export def "employer-sub-contractor-cis-lines-tags get-all" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/CisLines/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/JournalLines
# operationId: GetJournalLinesFromSubContractor
export def "employer-sub-contractor-journal-lines get-journal-lines-from" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/JournalLines"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an SubContractor revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: DeleteSubContractorRevisionByNumber
export def "employer-sub-contractor-revision delete" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the sub contractor by revision number
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: GetSubContractorRevisionByNumber
export def "employer-sub-contractor-revision get" [
  employer_id: string
  sub_contractor_id: string
  revision_number: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, revision_number: $revision_number} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revision/{revision_number}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor revisions
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revisions
# operationId: GetSubContractorRevisions
export def "employer-sub-contractor-revisions get" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Revisions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete sub contractor tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: DeleteSubContractorTag
export def "employer-sub-contractor-tag delete" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: GetTagFromSubContractor
export def "employer-sub-contractor-tag get-tag-from" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert sub contractor tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: PutSubContractorTag
export def "employer-sub-contractor-tag update" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor revision tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromSubContractorRevision
export def "employer-sub-contractor-tag get-tag-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, tag_id: $tag_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tag/{tag_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags
# operationId: GetTagsFromSubContractor
export def "employer-sub-contractor-tags get-tags-from" [
  employer_id: string
  sub_contractor_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor revision tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags/{EffectiveDate}
# operationId: GetTagsFromSubContractorRevision
export def "employer-sub-contractor-tags get-tags-from-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/Tags/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an sub contractor revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: DeleteSubContractorRevision
export def "employer-sub-contractor delete-sub-contractor-revision" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor by effective date.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: GetSubContractorByEffectiveDate
export def "employer-sub-contractor get" [
  employer_id: string
  sub_contractor_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, sub_contractor_id: $sub_contractor_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/SubContractor/{sub_contractor_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractors from employer.
#
# GET /Employer/{EmployerId}/SubContractors
# operationId: GetSubContractorsFromEmployer
export def "employer-sub-contractors get-sub-contractors-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/SubContractors"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new sub contractor
#
# POST /Employer/{EmployerId}/SubContractors
# operationId: PostSubContractorIntoEmployer
# --SubContractor shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
export def "employer-sub-contractors create-sub-contractor-into" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --sub-contractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/SubContractors"))
  let body = {"SubContractor": $sub_contractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sub contractors with tag
#
# GET /Employer/{EmployerId}/SubContractors/Tag/{TagId}
# operationId: GetSubContractorsWithTag
export def "employer-sub-contractors-tag get-sub-contractors-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/SubContractors/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor tags
#
# GET /Employer/{EmployerId}/SubContractors/Tags
# operationId: GetAllSubContractorTags
export def "employer-sub-contractors-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/SubContractors/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractors from employer at a given effective date.
#
# GET /Employer/{EmployerId}/SubContractors/{EffectiveDate}
# operationId: GetSubContractorsByEffectiveDate
export def "employer-sub-contractors get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/SubContractors/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summary
#
# GET /Employer/{EmployerId}/Summary
# operationId: GetEmployerSummary
export def "employer-summary list" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete employer tag
#
# DELETE /Employer/{EmployerId}/Tag/{TagId}
# operationId: DeleteEmployerTag
export def "employer-tag delete" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}
# operationId: GetTagFromEmployer
export def "employer-tag get-tag-from" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert employer tag
#
# PUT /Employer/{EmployerId}/Tag/{TagId}
# operationId: PutEmployerTag
export def "employer-tag update" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer revision tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployerRevision
export def "employer-tag get-tag-from-employer-revision" [
  employer_id: string
  tag_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Tag/{tag_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer tags
#
# GET /Employer/{EmployerId}/Tags
# operationId: GetTagsFromEmployer
export def "employer-tags get-tags-from" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer revision tags
#
# GET /Employer/{EmployerId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployerRevision
export def "employer-tags get-tags-from-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/Tags/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete third party transaction
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: DeleteThirdPartyTransaction
export def "employer-third-party-transaction delete" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: GetThirdPartyTransaction
export def "employer-third-party-transaction get" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete third party transaction tag
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: DeleteThirdPartyTransactionTag
export def "employer-third-party-transaction-tag delete" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get third party transaction tag
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: GetTagFromThirdPartyTransaction
export def "employer-third-party-transaction-tag get-tag-from" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# insert third party transaction tag
#
# PUT /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: PutThirdPartyTransactionTag
export def "employer-third-party-transaction-tag update" [
  employer_id: string
  third_party_transaction_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tags
# operationId: GetTagsFromThirdPartyTransaction
export def "employer-third-party-transaction-tags get-tags-from" [
  employer_id: string
  third_party_transaction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, third_party_transaction_id: $third_party_transaction_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransaction/{third_party_transaction_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all third party transaction links
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions
# operationId: GetThirdPartyTransactions
export def "employer-third-party-transactions get" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged third party transactions
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tag/{TagId}
# operationId: GetAllThirdPartyTransactionsWithTag
export def "employer-third-party-transactions-tag get-all-third-party-transactions-with" [
  employer_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, tag_id: $tag_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all third party transaction tags
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tags
# operationId: GetAllThirdPartyTransactionTags
export def "employer-third-party-transactions-tags get-all" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Employer/{employer_id}/ThirdPartyTransactions/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employer revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/{EffectiveDate}
# operationId: DeleteEmployerRevision
export def "employer delete-employer-revision" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer at the specified effective
#
# GET /Employer/{EmployerId}/{EffectiveDate}
# operationId: GetEmployerByEffectiveDate
export def "employer get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summary by effective date.
#
# GET /Employer/{EmployerId}/{EffectiveDate}/Summary
# operationId: GetEmployerSummaryByEffectiveDate
export def "employer-summary get" [
  employer_id: string
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id, effective_date: $effective_date} | format pattern "/Employer/{employer_id}/{effective_date}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all employers
#
# GET /Employers
# operationId: GetEmployers
export def "employers list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Employer
#
# POST /Employers
# operationId: PostEmployer
# --Employer shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
export def "employers create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers")
  let body = {"Employer": $employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get employer summaries.
#
# GET /Employers/Summary
# operationId: GetEmployerSummaries
export def "employers-summary list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Summary")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employers with tag
#
# GET /Employers/Tag/{TagId}
# operationId: GetEmployersWithTag
export def "employers-tag get-employers-with" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: $tag_id} | format pattern "/Employers/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer tags
#
# GET /Employers/Tags
# operationId: GetAllEmployerTags
export def "employers-tags get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Tags")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all employers at the specified effective date
#
# GET /Employers/{EffectiveDate}
# operationId: GetEmployersByEffectiveDate
export def "employers get" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({effective_date: $effective_date} | format pattern "/Employers/{effective_date}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summaries at a given effective date.
#
# GET /Employers/{EffectiveDate}/Summary
# operationId: GetEmployerSummariesByEffectiveDate
export def "employers-summary get-employer-summaries" [
  effective_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({effective_date: $effective_date} | format pattern "/Employers/{effective_date}/Summary"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get health check status
#
# GET /Healthcheck
# operationId: GetHealthCheck
export def "healthcheck get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<HealthCheck: record<Info: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Healthcheck")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Batch jobs
#
# GET /Jobs/Batch
# operationId: GetBatchJobs
export def "jobs-batch get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Batch job
#
# POST /Jobs/Batch
# operationId: PostNewBatchJob
# --BatchJobInstruction shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
export def "jobs-batch create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --batch-job-instruction: record # shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch")
  let body = {"BatchJobInstruction": $batch_job_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Batch job
#
# DELETE /Jobs/Batch/{JobId}
# operationId: DeleteBatchJob
export def "jobs-batch delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Batch/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job information
#
# GET /Jobs/Batch/{JobId}/Info
# operationId: GetBatchJobInfo
export def "jobs-batch-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Batch/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job progress
#
# GET /Jobs/Batch/{JobId}/Progress
# operationId: GetBatchJobProgress
export def "jobs-batch-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Batch/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job status
#
# GET /Jobs/Batch/{JobId}/Status
# operationId: GetBatchJobStatus
export def "jobs-batch-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Batch/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS jobs
#
# GET /Jobs/Cis
# operationId: GetCisJobs
export def "jobs-cis get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new CIS job
#
# POST /Jobs/Cis
# operationId: PostNewCisJob
# --CisJobInstructionBase shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
export def "jobs-cis create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --cis-job-instruction-base: record # shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis")
  let body = {"CisJobInstructionBase": $cis_job_instruction_base} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the CIS job
#
# DELETE /Jobs/Cis/{JobId}
# operationId: DeleteCisJob
export def "jobs-cis delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Cis/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job information
#
# GET /Jobs/Cis/{JobId}/Info
# operationId: GetCisJobInfo
export def "jobs-cis-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Cis/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job progress
#
# GET /Jobs/Cis/{JobId}/Progress
# operationId: GetCisJobProgress
export def "jobs-cis-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Cis/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job status
#
# GET /Jobs/Cis/{JobId}/Status
# operationId: GetCisJobStatus
export def "jobs-cis-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Cis/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all DPS jobs
#
# GET /Jobs/Dps
# operationId: GetDpsJobs
export def "jobs-dps get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new DPS job
#
# POST /Jobs/Dps
# operationId: PostNewDpsJob
# --DpsJobInstruction shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
export def "jobs-dps create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --dps-job-instruction: record # shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps")
  let body = {"DpsJobInstruction": $dps_job_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the DPS job
#
# DELETE /Jobs/Dps/{JobId}
# operationId: DeleteDpsJob
export def "jobs-dps delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Dps/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job information
#
# GET /Jobs/Dps/{JobId}/Info
# operationId: GetDpsJobInfo
export def "jobs-dps-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Dps/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job progress
#
# GET /Jobs/Dps/{JobId}/Progress
# operationId: GetDpsJobProgress
export def "jobs-dps-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Dps/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job status
#
# GET /Jobs/Dps/{JobId}/Status
# operationId: GetDpsJobStatus
export def "jobs-dps-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Dps/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all jobs relating to the employer.
#
# GET /Jobs/Employer/{EmployerId}
# operationId: GetEmployerJobs
export def "jobs-employer get" [
  employer_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({employer_id: $employer_id} | format pattern "/Jobs/Employer/{employer_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all PayRun jobs
#
# GET /Jobs/PayRuns
# operationId: GetPayRunJobs
export def "jobs-pay-runs get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new PayRun job
#
# POST /Jobs/PayRuns
# operationId: PostNewPayRunJob
# --PayRunJobInstruction shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
export def "jobs-pay-runs create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --pay-run-job-instruction: record # shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns")
  let body = {"PayRunJobInstruction": $pay_run_job_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the pay run job
#
# DELETE /Jobs/PayRuns/{JobId}
# operationId: DeletePayRunJob
export def "jobs-pay-runs delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/PayRuns/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job information
#
# GET /Jobs/PayRuns/{JobId}/Info
# operationId: GetPayRunJobInfo
export def "jobs-pay-runs-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/PayRuns/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job progress
#
# GET /Jobs/PayRuns/{JobId}/Progress
# operationId: GetPayRunJobProgress
export def "jobs-pay-runs-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/PayRuns/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job status
#
# GET /Jobs/PayRuns/{JobId}/Status
# operationId: GetPayRunJobStatus
export def "jobs-pay-runs-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/PayRuns/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI jobs
#
# GET /Jobs/Rti
# operationId: GetRtiJobs
export def "jobs-rti get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new RTI job
#
# POST /Jobs/Rti
# operationId: PostNewRtiJob
# --RtiJobInstruction shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
export def "jobs-rti create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --rti-job-instruction: record # shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti")
  let body = {"RtiJobInstruction": $rti_job_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the RTI job
#
# DELETE /Jobs/Rti/{JobId}
# operationId: DeleteRtiJob
export def "jobs-rti delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Rti/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job information
#
# GET /Jobs/Rti/{JobId}/Info
# operationId: GetRtiJobInfo
export def "jobs-rti-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Rti/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job progress
#
# GET /Jobs/Rti/{JobId}/Progress
# operationId: GetRtiJobProgress
export def "jobs-rti-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Rti/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job status
#
# GET /Jobs/Rti/{JobId}/Status
# operationId: GetRtiJobStatus
export def "jobs-rti-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/Rti/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Third Party jobs
#
# GET /Jobs/ThirdParty
# operationId: GetThirdPartyJobs
export def "jobs-third-party get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create new Third Party job
#
# POST /Jobs/ThirdParty
# operationId: PostNewThirdPartyJob
# --ThirdPartyJobInstruction shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
export def "jobs-third-party create-new" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --third-party-job-instruction: record # shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty")
  let body = {"ThirdPartyJobInstruction": $third_party_job_instruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Third Party job
#
# DELETE /Jobs/ThirdParty/{JobId}
# operationId: DeleteThirdPartyJob
export def "jobs-third-party delete" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/ThirdParty/{job_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job information
#
# GET /Jobs/ThirdParty/{JobId}/Info
# operationId: GetThirdPartyJobInfo
export def "jobs-third-party-info get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/ThirdParty/{job_id}/Info"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job progress
#
# GET /Jobs/ThirdParty/{JobId}/Progress
# operationId: GetThirdPartyJobProgress
export def "jobs-third-party-progress get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/ThirdParty/{job_id}/Progress"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job status
#
# GET /Jobs/ThirdParty/{JobId}/Status
# operationId: GetThirdPartyJobStatus
export def "jobs-third-party-status get" [
  job_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({job_id: $job_id} | format pattern "/Jobs/ThirdParty/{job_id}/Status"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Journal instruction template
#
# DELETE /JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstructionTemplate
export def "journal-instruction delete-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({journal_instruction_id: $journal_instruction_id} | format pattern "/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions template for the application
#
# GET /JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionTemplate
export def "journal-instruction get-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({journal_instruction_id: $journal_instruction_id} | format pattern "/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Journal Instruction template
#
# PUT /JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstructionTemplate
export def "journal-instruction update-journal-instruction-template" [
  journal_instruction_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({journal_instruction_id: $journal_instruction_id} | format pattern "/JournalInstruction/{journal_instruction_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions templates for the application
#
# GET /JournalInstructions
# operationId: GetJournalInstructionTemplates
export def "journal-instructions get-journal-instruction-templates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Journal Instruction template
#
# POST /JournalInstructions
# operationId: PostJournalInstructionTemplate
export def "journal-instructions create-journal-instruction-template" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the permission object
#
# DELETE /Permission/{PermissionId}
# operationId: DeletePermission
export def "permission delete" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id} | format pattern "/Permission/{permission_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the permission object
#
# GET /Permission/{PermissionId}
# operationId: GetPermission
export def "permission get" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id} | format pattern "/Permission/{permission_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch permission object
#
# PATCH /Permission/{PermissionId}
# operationId: PatchPermission
export def "permission update-by-PermissionId" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id} | format pattern "/Permission/{permission_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts permisson object
#
# PUT /Permission/{PermissionId}
# operationId: PutPermission
export def "permission update-by-PermissionId-1" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id} | format pattern "/Permission/{permission_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Permission tag
#
# DELETE /Permission/{PermissionId}/Tag/{TagId}
# operationId: DeletePermissionTag
export def "permission-tag delete" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id, tag_id: $tag_id} | format pattern "/Permission/{permission_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Permission tag
#
# GET /Permission/{PermissionId}/Tag/{TagId}
# operationId: GetTagFromPermission
export def "permission-tag get-tag-from" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id, tag_id: $tag_id} | format pattern "/Permission/{permission_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert Permission tag
#
# PUT /Permission/{PermissionId}/Tag/{TagId}
# operationId: PutPermissionTag
export def "permission-tag update" [
  permission_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id, tag_id: $tag_id} | format pattern "/Permission/{permission_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from Permission
#
# GET /Permission/{PermissionId}/Tags
# operationId: GetTagsFromPermission
export def "permission-tags get-tags-from" [
  permission_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({permission_id: $permission_id} | format pattern "/Permission/{permission_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all permission objects
#
# GET /Permissions
# operationId: GetPermissions
export def "permissions get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post permisson object
#
# POST /Permissions
# operationId: PostPermission
export def "permissions create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged Permissions
#
# GET /Permissions/Tag/{TagId}
# operationId: GetAllPermissionsWithTag
export def "permissions-tag get-all-permissions-with" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: $tag_id} | format pattern "/Permissions/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Permission tags
#
# GET /Permissions/Tags
# operationId: GetAllPermissionTags
export def "permissions-tags get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions/Tags")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the query result
#
# POST /Query
# operationId: GetQueryResponse
# --Query shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
export def "query get-query-response" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --query: record # shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Query")
  let body = {"Query": $query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the journal expression data schema
#
# GET /ReferenceData/JournalExpressionDataTable
# operationId: GetJournalExpressionSchema
export def "reference-data-journal-expression-data-table get-journal-expression-schema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ReferenceData/JournalExpressionDataTable")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the active pay instructions report
#
# GET /Report/ACTPAYINS/run
# operationId: GetActivePayInstructionsReportOutput
export def "report-actpayins-run get-active-pay-instructions-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --active-on: string # The active date to consider. E.g 2017-04-05 (format: date)
  --from-date: string # The lower filter date. E.g 2016-04-06 (format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --type: string # the data type to filter on. E.g. TaxPayInstruction
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar") (serialize-qp "ActiveOn" $active_on "scalar") (serialize-qp "FromDate" $from_date "scalar") (serialize-qp "ToDate" $to_date "scalar") (serialize-qp "Type" $type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/ACTPAYINS/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the AOE liability report
#
# GET /Report/AOELIABILITY/run
# operationId: GetAoeLiabilityReportOuput
export def "report-aoeliability-run get-aoe-liability-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/AOELIABILITY/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the DPS message report
#
# GET /Report/DPSMSG/run
# operationId: GetDpsMessageReportOutput
export def "report-dpsmsg-run get-dps-message-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --from-date: string # The lower filter date. E.g 2016-04-06 (format: date)
  --to-date: string # The upper filter date. E.g 2017-04-05 (format: date)
  --message-types: string # The DPS message types as a CSV list. E.g. P6,P9,SL1,SL2
  --message-statuses: string # The DPS message status as a CSV list. E.g. Retrieved,Processed,Blocked,Ignored
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "FromDate" $from_date "scalar") (serialize-qp "ToDate" $to_date "scalar") (serialize-qp "MessageTypes" $message_types "scalar") (serialize-qp "MessageStatuses" $message_statuses "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/DPSMSG/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the employer summary report
#
# GET /Report/EMPSUM/run
# operationId: GetEmployerSummaryReportOuput
export def "report-empsum-run get-employer-summary-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --context-date: string # The date context for the report. E.g. 2018-04-30 (format: date)
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "ContextDate" $context_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/EMPSUM/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the gross to net report
#
# GET /Report/GRO2NET/run
# operationId: GetGrossToNetReportOutput
export def "report-gro2net-run get-gross-to-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/GRO2NET/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the holiday balance report
#
# GET /Report/HOLBAL/run
# operationId: GetHolidayBalanceReportOutput
export def "report-holbal-run get-holiday-balance-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --holiday-year-end: string # The holiday year end for the report. E.g. 2018-12-31 (format: date)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "HolidayYearEnd" $holiday_year_end "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/HOLBAL/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the journal report
#
# GET /Report/JOURNAL/run
# operationId: GetJournalReportOuput
export def "report-journal-run get-journal-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-frequency: string # The pay frequency option. E.g. Monthly
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --ledger-target: string # Specific to JOURNAL report, a filter used to select the journal lines for the specified ledger target. E.g. [Default]
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayFrequency" $pay_frequency "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "LedgerTarget" $ledger_target "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/JOURNAL/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the last pay date report
#
# GET /Report/LASTPAYDATE/run
# operationId: GetLastPayDateReportOuput
export def "report-lastpaydate-run get-last-pay-date-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/LASTPAYDATE/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the net pay report
#
# GET /Report/NETPAY/run
# operationId: GetNetPayReportOutput
export def "report-netpay-run get-net-pay-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --tax-period: string # The tax period number. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "TaxPeriod" $tax_period "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NETPAY/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the next pay period report
#
# GET /Report/NEXTPERIOD/run
# operationId: GetNextPayPeriodDatesReportOutput
export def "report-nextperiod-run get-next-pay-period-dates-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NEXTPERIOD/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P11 summary report
#
# GET /Report/P11SUM/run
# operationId: GetP11SummaryReportOutput
export def "report-p11sum-run get-p11-summary-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P11SUM/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P32 report
#
# GET /Report/P32/run
# operationId: GetP32NetReportOutput
export def "report-p32-run get-p32-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P32 summary report
#
# GET /Report/P32SUM/run
# operationId: GetP32SummaryNetReportOutput
export def "report-p32sum-run get-p32-summary-net-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32SUM/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P45 report
#
# GET /Report/P45/run
# operationId: GetP45ReportOutput
export def "report-p45-run get-p45-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --employee-key: string # The employee unique key. E.g. EE001
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "EmployeeKey" $employee_key "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P45/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P60 report
#
# GET /Report/P60/run
# operationId: GetP60ReportOutput
export def "report-p60-run get-p60-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P60/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the PAPDIS report
#
# GET /Report/PAPDIS/run
# operationId: GetPapdisReportOuput
export def "report-papdis-run get-papdis-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PensionKey" $pension_key "scalar") (serialize-qp "MessageFunctionCode" $message_function_code "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAPDIS/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the PASS report
#
# GET /Report/PASS/run
# operationId: GetPassReportOuput
export def "report-pass-run get-pass-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --message-function-code: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --intermediary-id: string # Specific to PensionSync PASS report, a unique identifier for the Intermediary who is acting on behalf of the employer.
  --document-id: string # Specific to PensionSync PASS report, a document identifier unique for this document within the Intermediary.
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PensionKey" $pension_key "scalar") (serialize-qp "MessageFunctionCode" $message_function_code "scalar") (serialize-qp "IntermediaryId" $intermediary_id "scalar") (serialize-qp "DocumentId" $document_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PASS/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the Pay Dashboard payslips report
#
# GET /Report/PAYDASHBOARD/run
# operationId: GetPayDashboardPayslipReportOuput
export def "report-paydashboard-run get-pay-dashboard-payslip-report-ouput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --publication-date: string # Specific to the Pay Dashboard report, allows the specification of a future payslip publication date. E.g. 2018-12-31 (format: date)
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar") (serialize-qp "PaymentDate" $payment_date "scalar") (serialize-qp "PublicationDate" $publication_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYDASHBOARD/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the verbose payslip report
#
# GET /Report/PAYSLIP3/run
# operationId: GetPayslip3ReportOutput
export def "report-payslip3-run get-payslip3-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --pay-schedule-key: string # The pay schedule unique key. E.g. SCH001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --employee-codes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --transform-definition-key: string # The transform definition unique key. E.g. P45-Pdf
  --start-index: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --max-index: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --payment-date: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "PayScheduleKey" $pay_schedule_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "EmployeeCodes" $employee_codes "scalar") (serialize-qp "TransformDefinitionKey" $transform_definition_key "scalar") (serialize-qp "StartIndex" $start_index "scalar") (serialize-qp "MaxIndex" $max_index "scalar") (serialize-qp "PaymentDate" $payment_date "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYSLIP3/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the pension liability report
#
# GET /Report/PENLIABILITY/run
# operationId: GetPensionLiabilityReportOutput
export def "report-penliability-run get-pension-liability-report-output" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --employer-key: string # The employer unique key. E.g. ER001
  --tax-year: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --pension-key: string # The pension scheme unique key. E.g. PENSCH001
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $employer_key "scalar") (serialize-qp "TaxYear" $tax_year "scalar") (serialize-qp "PensionKey" $pension_key "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PENLIABILITY/run" $qp)
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a report definition
#
# DELETE /Report/{ReportDefinitionId}
# operationId: DeleteReportDefinition
export def "report delete-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_definition_id: $report_definition_id} | format pattern "/Report/{report_definition_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the report definition
#
# GET /Report/{ReportDefinitionId}
# operationId: GetReportDefinitionFromApplication
export def "report get-report-definition-from-application" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_definition_id: $report_definition_id} | format pattern "/Report/{report_definition_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a report definition
#
# PUT /Report/{ReportDefinitionId}
# operationId: PutReportDefinition
# --ReportDefinition shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
export def "report update-report-definition" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_definition_id: $report_definition_id} | format pattern "/Report/{report_definition_id}"))
  let body = {"ReportDefinition": $report_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Runs the specified report definition
#
# GET /Report/{ReportDefinitionId}/run
# operationId: GetReportOutput
export def "report-run get-report-output" [
  report_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({report_definition_id: $report_definition_id} | format pattern "/Report/{report_definition_id}/run"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all reports
#
# GET /Reports
# operationId: GetReportDefinitionsFromApplication
export def "reports get-report-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new report definition
#
# POST /Reports
# operationId: PostReportDefinition
# --ReportDefinition shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
export def "reports create-report-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --report-definition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let body = {"ReportDefinition": $report_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all available schemas
#
# GET /Schemas
# operationId: GetSchemas
export def "schemas list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Schemas")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get XSD schema
#
# GET /Schemas/{DtoDataType}
# operationId: GetSchema
export def "schemas get" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dto_data_type: $dto_data_type} | format pattern "/Schemas/{dto_data_type}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes Application secret
#
# DELETE /Secret/{SecretId}
# operationId: DeleteApplicationSecret
export def "secret delete-application" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Application secret
#
# GET /Secret/{SecretId}
# operationId: GetApplicationSecret
export def "secret get-application" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Application secret
#
# PUT /Secret/{SecretId}
# operationId: PutApplicationSecret
export def "secret update-application" [
  secret_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({secret_id: $secret_id} | format pattern "/Secret/{secret_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Application secret links
#
# GET /Secrets
# operationId: GetApplicationSecrets
export def "secrets get-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Application secret
#
# POST /Secrets
# operationId: PostApplicationSecret
export def "secrets create-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the object template
#
# GET /Template/{DtoDataType}
# operationId: GetTemplateModel
export def "template get-template-model" [
  dto_data_type: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({dto_data_type: $dto_data_type} | format pattern "/Template/{dto_data_type}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all available data object tempaltes
#
# GET /Templates
# operationId: GetTemplates
export def "templates get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Templates")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a transform definition
#
# DELETE /Transform/{TransformDefinitionId}
# operationId: DeleteTransformDefinition
export def "transform delete-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transform_definition_id: $transform_definition_id} | format pattern "/Transform/{transform_definition_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the transform definition
#
# GET /Transform/{TransformDefinitionId}
# operationId: GetTransformDefinitionFromApplication
export def "transform get-transform-definition-from-application" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transform_definition_id: $transform_definition_id} | format pattern "/Transform/{transform_definition_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a transform definition
#
# PUT /Transform/{TransformDefinitionId}
# operationId: PutTransformDefinition
# --TransformDefinition shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
export def "transform update-transform-definition" [
  transform_definition_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({transform_definition_id: $transform_definition_id} | format pattern "/Transform/{transform_definition_id}"))
  let body = {"TransformDefinition": $transform_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all transform definitions
#
# GET /Transforms
# operationId: GetTransformDefinitionsFromApplication
export def "transforms get-transform-definitions-from-application" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new transform definition
#
# POST /Transforms
# operationId: PostTransformDefinition
# --TransformDefinition shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
export def "transforms create-transform-definition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --transform-definition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms")
  let body = {"TransformDefinition": $transform_definition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the user object
#
# DELETE /User/{UserId}
# operationId: DeleteUser
export def "user delete" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user object
#
# GET /User/{UserId}
# operationId: GetUser
export def "user get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch user object
#
# PATCH /User/{UserId}
# operationId: PatchUser
export def "user update-by-UserId" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts user object
#
# PUT /User/{UserId}
# operationId: PutUser
export def "user update-by-UserId-1" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user permissions
#
# GET /User/{UserId}/Permissions
# operationId: GetUserPermissions
export def "user-permissions get" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}/Permissions"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user tag
#
# DELETE /User/{UserId}/Tag/{TagId}
# operationId: DeleteUserTag
export def "user-tag delete" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, tag_id: $tag_id} | format pattern "/User/{user_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user tag
#
# GET /User/{UserId}/Tag/{TagId}
# operationId: GetTagFromUser
export def "user-tag get-tag-from" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, tag_id: $tag_id} | format pattern "/User/{user_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert user tag
#
# PUT /User/{UserId}/Tag/{TagId}
# operationId: PutUserTag
export def "user-tag update" [
  user_id: string
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id, tag_id: $tag_id} | format pattern "/User/{user_id}/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from user
#
# GET /User/{UserId}/Tags
# operationId: GetTagsFromUser
export def "user-tags get-tags-from" [
  user_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({user_id: $user_id} | format pattern "/User/{user_id}/Tags"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all user objects
#
# GET /Users
# operationId: GetUsers
export def "users get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post user object
#
# POST /Users
# operationId: PostUser
export def "users create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged users
#
# GET /Users/Tag/{TagId}
# operationId: GetAllUsersWithTag
export def "users-tag get-all-users-with" [
  tag_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({tag_id: $tag_id} | format pattern "/Users/Tag/{tag_id}"))
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all user tags
#
# GET /Users/Tags
# operationId: GetAllUserTags
export def "users-tags get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --api-version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users/Tags")
  let extra_headers = {"Authorization": $authorization, "Api-Version": $api_version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
