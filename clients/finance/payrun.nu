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
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "employer DeleteEmployer" } } | get name | first)
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
export def "employer DeleteEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer
#
# GET /Employer/{EmployerId}
# operationId: GetEmployer
export def "employer GetEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer PatchEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)")
  let body = {Employer: $Employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer PutEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)")
  let body = {Employer: $Employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an CIS line type
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: DeleteCisLineType
export def "employer-cis-line-type DeleteCisLineType" [
  EmployerId: string
  CisLineTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line type from employer
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}
# operationId: GetCisLineTypeFromEmployer
export def "employer-cis-line-type GetCisLineTypeFromEmployer" [
  EmployerId: string
  CisLineTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-cis-line-type PutCisLineTypeIntoEmployer" [
  EmployerId: string
  CisLineTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --CisLineType: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<CisLineType: record<Description: string, LineType: string, NominalCode: record<_href: string, _rel: string, _title: string>, TaxTreatment: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)")
  let body = {CisLineType: $CisLineType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete CIS line type tag
#
# DELETE /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: DeleteCisLineTypeTag
export def "employer-cis-line-type-tag DeleteCisLineTypeTag" [
  EmployerId: string
  CisLineTypeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line type tag
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: GetTagFromCisLineType
export def "employer-cis-line-type-tag GetTagFromCisLineType" [
  EmployerId: string
  CisLineTypeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS line type tag
#
# PUT /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tag/{TagId}
# operationId: PutCisLineTypeTag
export def "employer-cis-line-type-tag PutCisLineTypeTag" [
  EmployerId: string
  CisLineTypeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS line type
#
# GET /Employer/{EmployerId}/CisLineType/{CisLineTypeId}/Tags
# operationId: GetTagsFromCisLineType
export def "employer-cis-line-type-tags GetTagsFromCisLineType" [
  EmployerId: string
  CisLineTypeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineType/($CisLineTypeId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line types from employer.
#
# GET /Employer/{EmployerId}/CisLineTypes
# operationId: GetCisLineTypesFromEmployer
export def "employer-cis-line-types GetCisLineTypesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineTypes")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-cis-line-types PostCisLineTypeIntoEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --CisLineType: record # shape: {Description?: string, LineType?: string, NominalCode?: record, TaxTreatment?: "Taxable"|"NonTaxable"|"Notional"|"Materials"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineTypes")
  let body = {CisLineType: $CisLineType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CIS line types with tag
#
# GET /Employer/{EmployerId}/CisLineTypes/Tag/{TagId}
# operationId: GetCisLineTypesWithTag
export def "employer-cis-line-types-tag GetCisLineTypesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineTypes/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS line type tags
#
# GET /Employer/{EmployerId}/CisLineTypes/Tags
# operationId: GetAllCisLineTypeTags
export def "employer-cis-line-types-tags GetAllCisLineTypeTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisLineTypes/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the CIS transaction
#
# DELETE /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: DeleteCisTransaction
export def "employer-cis-transaction DeleteCisTransaction" [
  EmployerId: string
  CisTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisTransaction/($CisTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS transaction
#
# GET /Employer/{EmployerId}/CisTransaction/{CisTransactionId}
# operationId: GetCisTransactionFromEmployer
export def "employer-cis-transaction GetCisTransactionFromEmployer" [
  EmployerId: string
  CisTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisTransaction: record<CisMessageType: string, EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisTransaction/($CisTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS transactions for the employer
#
# GET /Employer/{EmployerId}/CisTransactions
# operationId: GetCisTransactionsFromEmployer
export def "employer-cis-transactions GetCisTransactionsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/CisTransactions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the DPS message
#
# DELETE /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: DeleteDpsMessage
export def "employer-dps-message DeleteDpsMessage" [
  EmployerId: string
  DpsMessageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessage/($DpsMessageId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the DPS message
#
# GET /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: GetDpsMessageFromEmployer
export def "employer-dps-message GetDpsMessageFromEmployer" [
  EmployerId: string
  DpsMessageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessage/($DpsMessageId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the DPS message
#
# PATCH /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PatchDpsMessage
export def "employer-dps-message PatchDpsMessage" [
  EmployerId: string
  DpsMessageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessage/($DpsMessageId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts the DPS message
#
# PUT /Employer/{EmployerId}/DpsMessage/{DpsMessageId}
# operationId: PutDpsMessage
export def "employer-dps-message PutDpsMessage" [
  EmployerId: string
  DpsMessageId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<DpsMessage: record<FormType: string, IssueDate: string, LastUpdated: string, Message: string, MessageStatus: string, MessageType: string, ProcessingResult: string, RetrieveDate: string, SequenceNumber: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessage/($DpsMessageId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the DPS messages
#
# GET /Employer/{EmployerId}/DpsMessages
# operationId: GetDpsMessagesFromEmployer
export def "employer-dps-messages GetDpsMessagesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessages")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Posta the DPS message
#
# POST /Employer/{EmployerId}/DpsMessages
# operationId: PostDpsMessage
export def "employer-dps-messages PostDpsMessage" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/DpsMessages")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: DeleteEmployee
export def "employer-employee DeleteEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}
# operationId: GetEmployeeFromEmployer
export def "employer-employee GetEmployeeFromEmployer" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee PatchEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)")
  let body = {Employee: $Employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee PutEmployeeIntoEmployer" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)")
  let body = {Employee: $Employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete auto enrolment assessment
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: DeleteAEAssessment
export def "employer-employee-ae-assessment DeleteAEAssessment" [
  EmployerId: string
  EmployeeId: string
  AEAssessmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/AEAssessment/($AEAssessmentId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto enrolment assessment
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessment/{AEAssessmentId}
# operationId: GetAEAssessmentFromEmployee
export def "employer-employee-ae-assessment GetAEAssessmentFromEmployee" [
  EmployerId: string
  EmployeeId: string
  AEAssessmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/AEAssessment/($AEAssessmentId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee-ae-assessment PutNewAEAssessment" [
  EmployerId: string
  EmployeeId: string
  AEAssessmentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --AEAssessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
]: any -> record<AEAssessment: record<Age: int, AssessmentCode: string, AssessmentDate: string, AssessmentEvent: string, AssessmentOverride: string, AssessmentResult: string, IsMemberOfAlternativePensionScheme: bool, OptOutWindowEndDate: string, QualifyingEarnings: float, ReenrolmentDate: string, StatePensionAge: int, StatePensionDate: string, TaxPeriod: int, TaxYear: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/AEAssessment/($AEAssessmentId)")
  let body = {AEAssessment: $AEAssessment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/AEAssessments
# operationId: GetAEAssessmentsFromEmployee
export def "employer-employee-ae-assessments GetAEAssessmentsFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/AEAssessments")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee-ae-assessments PostNewAEAssessment" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --AEAssessment: record # shape: {Age?: int, AssessmentCode?: "Excluded"|"EligibleJobHolder"|"NonEligibleJobHolder"|"EntitledWorker", AssessmentDate?: string, AssessmentEvent?: "NonEnrolmentEvent"|"AutomaticEnrolment"|"OptIn"|"VoluntaryJoiner"|"ContractualEnrolment", AssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AssessmentResult?: "Inconclusive"|"NoChange"|"Enrol"|"Exit", IsMemberOfAlternativePensionScheme?: bool, OptOutWindowEndDate?: string, QualifyingEarnings?: float, ReenrolmentDate?: string, StatePensionAge?: int, StatePensionDate?: string, TaxPeriod?: int, TaxYear?: int}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/AEAssessments")
  let body = {AEAssessment: $AEAssessment} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get links to all commentaries for the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentaries
# operationId: GetCommentariesFromEmployee
export def "employer-employee-commentaries GetCommentariesFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Commentaries")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commentary from employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Commentary/{CommentaryId}
# operationId: GetCommentaryFromEmployee
export def "employer-employee-commentary GetCommentaryFromEmployee" [
  EmployerId: string
  EmployeeId: string
  CommentaryId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Commentary/($CommentaryId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/JournalLines
# operationId: GetJournalLinesFromEmployee
export def "employer-employee-journal-lines GetJournalLinesFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/JournalLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay instruction
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: DeletePayInstruction
export def "employer-employee-pay-instruction DeletePayInstruction" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay instruction from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}
# operationId: GetPayInstructionFromEmployee
export def "employer-employee-pay-instruction GetPayInstructionFromEmployee" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee-pay-instruction PatchPayInstruction" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayInstruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)")
  let body = {PayInstruction: $PayInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee-pay-instruction PutPayInstruction" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayInstruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<PayInstruction: record<Description: string, EndDate: string, PayLineTag: string, StartDate: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)")
  let body = {PayInstruction: $PayInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete pay instruction tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: DeletePayInstructionTag
export def "employer-employee-pay-instruction-tag DeletePayInstructionTag" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay instruction tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: GetTagFromPayInstruction
export def "employer-employee-pay-instruction-tag GetTagFromPayInstruction" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay instruction tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tag/{TagId}
# operationId: PutPayInstructionTag
export def "employer-employee-pay-instruction-tag PutPayInstructionTag" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the pay instruction
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstruction/{PayInstructionId}/Tags
# operationId: GetTagsFromPayInstruction
export def "employer-employee-pay-instruction-tags GetTagsFromPayInstruction" [
  EmployerId: string
  EmployeeId: string
  PayInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstruction/($PayInstructionId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay instructions from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions
# operationId: GetPayInstructionsFromEmployee
export def "employer-employee-pay-instructions GetPayInstructionsFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employee-pay-instructions PostPayInstruction" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayInstruction: record # shape: {Description?: string, EndDate?: string, PayLineTag?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstructions")
  let body = {PayInstruction: $PayInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay instructions with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tag/{TagId}
# operationId: GetPayInstructionsWithTag
export def "employer-employee-pay-instructions-tag GetPayInstructionsWithTag" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstructions/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay instruction tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayInstructions/Tags
# operationId: GetAllPayInstructionTags
export def "employer-employee-pay-instructions-tags GetAllPayInstructionTags" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayInstructions/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay line from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}
# operationId: GetPayLineFromEmployee
export def "employer-employee-pay-line GetPayLineFromEmployee" [
  EmployerId: string
  EmployeeId: string
  PayLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayLine: record<Calculator: string, Description: string, Generated: string, PayCode: string, PayCodeType: string, PayRunSequence: int, PaymentDate: string, TaxPeriod: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLine/($PayLineId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay line tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: DeletePayLineTag
export def "employer-employee-pay-line-tag DeletePayLineTag" [
  EmployerId: string
  EmployeeId: string
  PayLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLine/($PayLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay line tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: GetTagFromPayLine
export def "employer-employee-pay-line-tag GetTagFromPayLine" [
  EmployerId: string
  EmployeeId: string
  PayLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLine/($PayLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay line tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tag/{TagId}
# operationId: PutPayLineTag
export def "employer-employee-pay-line-tag PutPayLineTag" [
  EmployerId: string
  EmployeeId: string
  PayLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLine/($PayLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the pay line
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLine/{PayLineId}/Tags
# operationId: GetTagsFromPayLine
export def "employer-employee-pay-line-tags GetTagsFromPayLine" [
  EmployerId: string
  EmployeeId: string
  PayLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLine/($PayLineId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay lines from the specified employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines
# operationId: GetPayLinesFromEmployee
export def "employer-employee-pay-lines GetPayLinesFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay lines with tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tag/{TagId}
# operationId: GetPayLinesWithTag
export def "employer-employee-pay-lines-tag GetPayLinesWithTag" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLines/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay line tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayLines/Tags
# operationId: GetAllPayLineTags
export def "employer-employee-pay-lines-tags GetAllPayLineTags" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayLines/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay runs from the employee
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/PayRuns
# operationId: GetPayRunsFromEmployee
export def "employer-employee-pay-runs GetPayRunsFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/PayRuns")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: DeleteEmployeeRevisionByNumber
export def "employer-employee-revision DeleteEmployeeRevisionByNumber" [
  EmployerId: string
  EmployeeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employee by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}
# operationId: GetEmployeeRevisionByNumber
export def "employer-employee-revision GetEmployeeRevisionByNumber" [
  EmployerId: string
  EmployeeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employee summary by revision number
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployeeRevisionSummaryByNumber
export def "employer-employee-revision-summary GetEmployeeRevisionSummaryByNumber" [
  EmployerId: string
  EmployeeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Revision/($RevisionNumber)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revisions
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions
# operationId: GetEmployeeRevisions
export def "employer-employee-revisions GetEmployeeRevisions" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revision summaries
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Revisions/Summary
# operationId: GetEmployeeRevisionSummaries
export def "employer-employee-revisions-summary GetEmployeeRevisionSummaries" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Revisions/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes employee secret
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: DeleteEmployeeSecret
export def "employer-employee-secret DeleteEmployeeSecret" [
  EmployerId: string
  EmployeeId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee secret
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: GetEmployeeSecret
export def "employer-employee-secret GetEmployeeSecret" [
  EmployerId: string
  EmployeeId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employee secret
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Secret/{SecretId}
# operationId: PutEmployeeSecret
export def "employer-employee-secret PutEmployeeSecret" [
  EmployerId: string
  EmployeeId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployeeSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee secret links
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: GetEmployeeSecrets
export def "employer-employee-secrets GetEmployeeSecrets" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employee secret
#
# POST /Employer/{EmployerId}/Employee/{EmployeeId}/Secrets
# operationId: PostEmployeeSecret
export def "employer-employee-secrets PostEmployeeSecret" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summary from employer
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Summary
# operationId: GetEmployeeSummaryFromEmployer
export def "employer-employee-summary GetEmployeeSummaryFromEmployer" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete employee tag
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: DeleteEmployeeTag
export def "employer-employee-tag DeleteEmployeeTag" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: GetTagFromEmployee
export def "employer-employee-tag GetTagFromEmployee" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert employee tag
#
# PUT /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}
# operationId: PutEmployeeTag
export def "employer-employee-tag PutEmployeeTag" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee revision tag
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployeeRevision
export def "employer-employee-tag GetTagFromEmployeeRevision" [
  EmployerId: string
  EmployeeId: string
  TagId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tag/($TagId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags
# operationId: GetTagsFromEmployee
export def "employer-employee-tags GetTagsFromEmployee" [
  EmployerId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee revision tags
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployeeRevision
export def "employer-employee-tags GetTagsFromEmployeeRevision" [
  EmployerId: string
  EmployeeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/Tags/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employee revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: DeleteEmployeeRevision
export def "employer-employee DeleteEmployeeRevision" [
  EmployerId: string
  EmployeeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}
# operationId: GetEmployeeByEffectiveDate
export def "employer-employee GetEmployeeByEffectiveDate" [
  EmployerId: string
  EmployeeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employee: record<AEAssessmentOverride: string, AEAssessmentOverrideDate: string, AEExclusionReasonCode: string, AEPostponementDate: string, Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, Code: string, DateOfBirth: string, Deactivated: bool, DirectorshipAppointmentDate: string, EEACitizen: bool, EPM6: bool, EffectiveDate: string, EmployeePartner: record<FirstName: string, Initials: string, LastName: string, MiddleName: string, NiNumber: string>, FirstName: string, Gender: string, HoursPerWeek: float, Initials: string, IrregularEmployment: bool, IsAgencyWorker: bool, LastName: string, LeaverReason: string, LeavingDate: string, MaritalStatus: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, NicLiability: string, OffPayrollWorker: bool, OnStrike: bool, P45IssuedDate: string, PassportNumber: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentMethod: string, PaymentToANonIndividual: bool, Region: string, Revision: int, RuleExclusions: string, Seconded: string, StartDate: string, StarterDeclaration: string, Territory: string, Title: string, VeteranPeriodStartDate: string, WorkingWeek: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summary by effective date.
#
# GET /Employer/{EmployerId}/Employee/{EmployeeId}/{EffectiveDate}/Summary
# operationId: GetEmployeeSummaryByEffectiveDate
export def "employer-employee-summary GetEmployeeSummaryByEffectiveDate" [
  EmployerId: string
  EmployeeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employee/($EmployeeId)/($EffectiveDate)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from employer.
#
# GET /Employer/{EmployerId}/Employees
# operationId: GetEmployeesFromEmployer
export def "employer-employees GetEmployeesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-employees PostEmployeeIntoEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employee: record # shape: {AEAssessmentOverride?: "None"|"OptOut"|"OptIn"|"VoluntaryJoiner"|"ContractualPension"|"CeasedMembership"|"Leaver"|"Excluded", AEAssessmentOverrideDate?: string, AEExclusionReasonCode?: "OtherNotKnown"|"NotAWorker"|"NotUKWorker"|"TemporaryUKWorker"|"OutsideAgeRange"|"SingleEmployeeDirector"|"CeasedMembershipWithin12Months"|"CeasedMembershipBeyond12Months"|"WorkerWULSWithin12Month"|"WorkerWULSBeyond12Month"|"WorkerInNoticePeriod"|"WorkerTaxProtection", AEPostponementDate?: string, Address?: record, BankAccount?: record, Code?: string, DateOfBirth?: string, Deactivated?: bool, DirectorshipAppointmentDate?: string, EEACitizen?: bool, EPM6?: bool, EffectiveDate?: string, EmployeePartner?: record, FirstName?: string, Gender?: "Unknown"|"Male"|"Female", HoursPerWeek?: float, Initials?: string, IrregularEmployment?: bool, IsAgencyWorker?: bool, LastName?: string, LeaverReason?: "Resigned"|"Dismissed"|"Redundant"|"Retired"|"Deceased"|"LegalCustody"|"Other", LeavingDate?: string, MaritalStatus?: "NotSet"|"Single"|"Married"|"Divorced"|"Widowed", MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, NicLiability?: "HasOtherJob"|"IsFemaleEntitledToReducedRate"|"IsNotLiable"|"IsContractedOut"|"IsFullyLiable"|"IsApprentice"|"LeaverBeyond6Weeks"|"PaymentAfterLeavingIrregular"|"IsFreePortWorker"|"IsNotLiableForEmployerNi", OffPayrollWorker?: bool, OnStrike?: bool, P45IssuedDate?: string, PassportNumber?: string, PaySchedule?: record, PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", PaymentToANonIndividual?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Seconded?: "NotSet"|"Stay183DaysOrMore"|"StayLessThan183Days"|"InOutUk", StartDate?: string, StarterDeclaration?: "PreviouslyReported"|"A"|"B"|"C", Territory?: "UnitedKingdom", Title?: string, VeteranPeriodStartDate?: string, WorkingWeek?: "None"|"Monday"|"Tuesday"|"Wednesday"|"Thursday"|"Friday"|"AllWeekDays"|"Saturday"|"Sunday"|"AllDays"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees")
  let body = {Employee: $Employee} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get employee summaries from employer.
#
# GET /Employer/{EmployerId}/Employees/Summary
# operationId: GetEmployeeSummariesFromEmployer
export def "employer-employees-summary GetEmployeeSummariesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees with tag
#
# GET /Employer/{EmployerId}/Employees/Tag/{TagId}
# operationId: GetEmployeesWithTag
export def "employer-employees-tag GetEmployeesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employee tags
#
# GET /Employer/{EmployerId}/Employees/Tags
# operationId: GetAllEmployeeTags
export def "employer-employees-tags GetAllEmployeeTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}
# operationId: GetEmployeesByEffectiveDate
export def "employer-employees GetEmployeesByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee summaries from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Employees/{EffectiveDate}/Summary
# operationId: GetEmployeeSummariesByEffectiveDate
export def "employer-employees-summary GetEmployeeSummariesByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Employees/($EffectiveDate)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an holiday scheme
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: DeleteHolidayScheme
export def "employer-holiday-scheme DeleteHolidayScheme" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme from employer
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}
# operationId: GetHolidaySchemeFromEmployer
export def "employer-holiday-scheme GetHolidaySchemeFromEmployer" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-holiday-scheme PatchHolidayScheme" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --HolidayScheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)")
  let body = {HolidayScheme: $HolidayScheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-holiday-scheme PutHolidaySchemeIntoEmployer" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --HolidayScheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)")
  let body = {HolidayScheme: $HolidayScheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an HolidayScheme revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: DeleteHolidaySchemeRevisionByNumber
export def "employer-holiday-scheme-revision DeleteHolidaySchemeRevisionByNumber" [
  EmployerId: string
  HolidaySchemeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the holiday scheme revision by revision number
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revision/{RevisionNumber}
# operationId: GetHolidaySchemeRevisionByNumber
export def "employer-holiday-scheme-revision GetHolidaySchemeRevisionByNumber" [
  EmployerId: string
  HolidaySchemeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme revisions
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Revisions
# operationId: GetHolidaySchemeRevisions
export def "employer-holiday-scheme-revisions GetHolidaySchemeRevisions" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete holiday scheme tag
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: DeleteHolidaySchemeTag
export def "employer-holiday-scheme-tag DeleteHolidaySchemeTag" [
  EmployerId: string
  HolidaySchemeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: GetTagFromHolidayScheme
export def "employer-holiday-scheme-tag GetTagFromHolidayScheme" [
  EmployerId: string
  HolidaySchemeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert holiday scheme tag
#
# PUT /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}
# operationId: PutHolidaySchemeTag
export def "employer-holiday-scheme-tag PutHolidaySchemeTag" [
  EmployerId: string
  HolidaySchemeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme revision tag
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromHolidaySchemeRevision
export def "employer-holiday-scheme-tag GetTagFromHolidaySchemeRevision" [
  EmployerId: string
  HolidaySchemeId: string
  TagId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tag/($TagId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the holiday scheme
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags
# operationId: GetTagsFromHolidayScheme
export def "employer-holiday-scheme-tags GetTagsFromHolidayScheme" [
  EmployerId: string
  HolidaySchemeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme revision tags
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/Tags/{EffectiveDate}
# operationId: GetTagsFromHolidaySchemeRevision
export def "employer-holiday-scheme-tags GetTagsFromHolidaySchemeRevision" [
  EmployerId: string
  HolidaySchemeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/Tags/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an holiday scheme revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: DeleteHolidaySchemeRevision
export def "employer-holiday-scheme DeleteHolidaySchemeRevision" [
  EmployerId: string
  HolidaySchemeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday scheme by effective date.
#
# GET /Employer/{EmployerId}/HolidayScheme/{HolidaySchemeId}/{EffectiveDate}
# operationId: GetHolidaySchemeByEffectiveDate
export def "employer-holiday-scheme GetHolidaySchemeByEffectiveDate" [
  EmployerId: string
  HolidaySchemeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<HolidayScheme: record<AccrualPayCodes: record<PayCode: list>, AllowExceedAnnualEntitlement: bool, AllowNegativeBalance: bool, AnnualEntitlementWeeks: float, BankHolidayInclusive: bool, Code: string, EffectiveDate: string, MaxCarryOverDays: float, NextRevisionDate: string, OffsetPayment: bool, Revision: int, SchemeCeasedDate: string, SchemeKey: string, SchemeName: string, YearStartDay: int, YearStartMonth: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidayScheme/($HolidaySchemeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday schemes from employer.
#
# GET /Employer/{EmployerId}/HolidaySchemes
# operationId: GetHolidaySchemesFromEmployer
export def "employer-holiday-schemes GetHolidaySchemesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidaySchemes")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-holiday-schemes PostHolidaySchemeIntoEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --HolidayScheme: record # shape: {AccrualPayCodes?: record, AllowExceedAnnualEntitlement?: bool, AllowNegativeBalance?: bool, AnnualEntitlementWeeks?: float, BankHolidayInclusive?: bool, Code?: string, EffectiveDate?: string, MaxCarryOverDays?: float, NextRevisionDate?: string, OffsetPayment?: bool, Revision?: int, SchemeCeasedDate?: string, SchemeKey?: string, SchemeName?: string, YearStartDay?: int, YearStartMonth?: int}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidaySchemes")
  let body = {HolidayScheme: $HolidayScheme} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get holiday schemes with tag
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tag/{TagId}
# operationId: GetHolidaySchemesWithTag
export def "employer-holiday-schemes-tag GetHolidaySchemesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidaySchemes/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all holiday scheme tags
#
# GET /Employer/{EmployerId}/HolidaySchemes/Tags
# operationId: GetAllHolidaySchemeTags
export def "employer-holiday-schemes-tags GetAllHolidaySchemeTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidaySchemes/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get holiday schemes from employer at a given effective date.
#
# GET /Employer/{EmployerId}/HolidaySchemes/{EffectiveDate}
# operationId: GetHolidaySchemesByEffectiveDate
export def "employer-holiday-schemes GetHolidaySchemesByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/HolidaySchemes/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Journal instruction
#
# DELETE /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstruction
export def "employer-journal-instruction DeleteJournalInstruction" [
  EmployerId: string
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified journal instruction from the employer
#
# GET /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionFromEmployer
export def "employer-journal-instruction GetJournalInstructionFromEmployer" [
  EmployerId: string
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Journal Instruction
#
# PUT /Employer/{EmployerId}/JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstruction
export def "employer-journal-instruction PutJournalInstruction" [
  EmployerId: string
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions from the specified employer
#
# GET /Employer/{EmployerId}/JournalInstructions
# operationId: GetJournalInstructionsFromEmployer
export def "employer-journal-instructions GetJournalInstructionsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Journal Instruction
#
# POST /Employer/{EmployerId}/JournalInstructions
# operationId: PostJournalInstruction
export def "employer-journal-instructions PostJournalInstruction" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified journal Line from the employer
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}
# operationId: GetJournalLineFromEmployer
export def "employer-journal-line GetJournalLineFromEmployer" [
  EmployerId: string
  JournalLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalLine: record<Credit: float, Debit: float, Description: string, Employee: record<_href: string, _rel: string, _title: string>, Generated: string, Grouping: string, LedgerTarget: string, NomCode: string, PayFrequency: string, PayRun: record<_href: string, _rel: string, _title: string>, SubContractor: record<_href: string, _rel: string, _title: string>, SubNomCode: string, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLine/($JournalLineId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete journal line tag
#
# DELETE /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: DeleteJournalLineTag
export def "employer-journal-line-tag DeleteJournalLineTag" [
  EmployerId: string
  JournalLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLine/($JournalLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get journal line tag
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: GetTagFromJournalLine
export def "employer-journal-line-tag GetTagFromJournalLine" [
  EmployerId: string
  JournalLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLine/($JournalLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert journal line tag
#
# PUT /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tag/{TagId}
# operationId: PutJournalLineTag
export def "employer-journal-line-tag PutJournalLineTag" [
  EmployerId: string
  JournalLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLine/($JournalLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from journal line
#
# GET /Employer/{EmployerId}/JournalLine/{JournalLineId}/Tags
# operationId: GetTagsFromJournalLine
export def "employer-journal-line-tags GetTagsFromJournalLine" [
  EmployerId: string
  JournalLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLine/($JournalLineId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal Lines from the specified employer
#
# GET /Employer/{EmployerId}/JournalLines
# operationId: GetJournalLinesFromEmployer
export def "employer-journal-lines GetJournalLinesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged journal lines
#
# GET /Employer/{EmployerId}/JournalLines/Tag/{TagId}
# operationId: GetAllJournalLinesWithTag
export def "employer-journal-lines-tag GetAllJournalLinesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLines/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all journal line tags
#
# GET /Employer/{EmployerId}/JournalLines/Tags
# operationId: GetAllJournalLineTags
export def "employer-journal-lines-tags GetAllJournalLineTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/JournalLines/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the nominal codes
#
# DELETE /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: DeleteNominalCode
export def "employer-nominal-code DeleteNominalCode" [
  EmployerId: string
  NominalCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCode/($NominalCodeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}
# operationId: GetNominalCodeFromEmployer
export def "employer-nominal-code GetNominalCodeFromEmployer" [
  EmployerId: string
  NominalCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<NominalCode: record<Description: string, Key: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCode/($NominalCodeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-nominal-code PutNominalCode" [
  EmployerId: string
  NominalCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --NominalCode: record # shape: {Description?: string, Key?: string}
]: any -> record<NominalCode: record<Description: string, Key: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCode/($NominalCodeId)")
  let body = {NominalCode: $NominalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the pay codes by nominal code
#
# GET /Employer/{EmployerId}/NominalCode/{NominalCodeId}/PayCodes
# operationId: GetPayCodesFromNominalCode
export def "employer-nominal-code-pay-codes GetPayCodesFromNominalCode" [
  EmployerId: string
  NominalCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCode/($NominalCodeId)/PayCodes")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the nominal codes
#
# GET /Employer/{EmployerId}/NominalCodes
# operationId: GetNominalCodesFromEmployer
export def "employer-nominal-codes GetNominalCodesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCodes")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-nominal-codes PostNominalCode" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --NominalCode: record # shape: {Description?: string, Key?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/NominalCodes")
  let body = {NominalCode: $NominalCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes a pay code
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: DeletePayCode
export def "employer-pay-code DeletePayCode" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay code from the employer
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}
# operationId: GetPayCodeFromEmployer
export def "employer-pay-code GetPayCodeFromEmployer" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pay-code PatchPayCode" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayCode: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)")
  let body = {PayCode: $PayCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pay-code PutPayCode" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayCode: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)")
  let body = {PayCode: $PayCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an PayCode revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: DeletePayCodeRevisionByNumber
export def "employer-pay-code-revision DeletePayCodeRevisionByNumber" [
  EmployerId: string
  PayCodeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay code by revision number
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revision/{RevisionNumber}
# operationId: GetPayCodeRevisionByNumber
export def "employer-pay-code-revision GetPayCodeRevisionByNumber" [
  EmployerId: string
  PayCodeId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all revisions of the Pay Code
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Revisions
# operationId: GetPayCodeRevisions
export def "employer-pay-code-revisions GetPayCodeRevisions" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay code tag
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: DeletePayCodeTag
export def "employer-pay-code-tag DeletePayCodeTag" [
  EmployerId: string
  PayCodeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay code tag
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: GetTagFromPayCode
export def "employer-pay-code-tag GetTagFromPayCode" [
  EmployerId: string
  PayCodeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay code tag
#
# PUT /Employer/{EmployerId}/PayCode/{PayCodeId}/Tag/{TagId}
# operationId: PutPayCodeTag
export def "employer-pay-code-tag PutPayCodeTag" [
  EmployerId: string
  PayCodeId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/Tags
# operationId: GetTagsFromPayCode
export def "employer-pay-code-tags GetTagsFromPayCode" [
  EmployerId: string
  PayCodeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay code revision
#
# DELETE /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: DeletePayCodeRevision
export def "employer-pay-code DeletePayCodeRevision" [
  EmployerId: string
  PayCodeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets pay code for specified date
#
# GET /Employer/{EmployerId}/PayCode/{PayCodeId}/{EffectiveDate}
# operationId: GetPayCodeByEffectiveDate
export def "employer-pay-code GetPayCodeByEffectiveDate" [
  EmployerId: string
  PayCodeId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayCode: record<Benefit: bool, Code: string, Description: string, EffectiveDate: string, MetaData: record, NextRevisionDate: string, Niable: bool, NominalCode: record<_href: string, _rel: string, _title: string>, NonArrestable: bool, Notional: bool, Readonly: bool, Region: string, Revision: int, Taxable: bool, Territory: string, Type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCode/($PayCodeId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay codes from the employer
#
# GET /Employer/{EmployerId}/PayCodes
# operationId: GetPayCodesFromEmployer
export def "employer-pay-codes GetPayCodesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCodes")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pay-codes PostPayCode" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayCode: record # shape: {Benefit?: bool, Code?: string, Description?: string, EffectiveDate?: string, MetaData?: record, NextRevisionDate?: string, Niable?: bool, NominalCode?: record, NonArrestable?: bool, Notional?: bool, Readonly?: bool, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, Taxable?: bool, Territory?: "UnitedKingdom", Type?: "NotSet"|"Payment"|"Deduction"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCodes")
  let body = {PayCode: $PayCode} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay codes with tag
#
# GET /Employer/{EmployerId}/PayCodes/Tag/{TagId}
# operationId: GetPayCodesWithTag
export def "employer-pay-codes-tag GetPayCodesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCodes/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay code tags
#
# GET /Employer/{EmployerId}/PayCodes/Tags
# operationId: GetAllPayCodeTags
export def "employer-pay-codes-tags GetAllPayCodeTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCodes/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all pay codes for specified date
#
# GET /Employer/{EmployerId}/PayCodes/{EffectiveDate}
# operationId: GetPayCodesByEffectiveDate
export def "employer-pay-codes GetPayCodesByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PayCodes/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay schedule
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: DeletePaySchedule
export def "employer-pay-schedule DeletePaySchedule" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified pay schedule from the employer
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}
# operationId: GetPayScheduleFromEmployer
export def "employer-pay-schedule GetPayScheduleFromEmployer" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pay-schedule PutPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PaySchedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<PaySchedule: record<MetaData: record, Name: string, PayFrequency: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)")
  let body = {PaySchedule: $PaySchedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all employees revisions from a pay schedule.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees
# operationId: GetEmployeesFromPaySchedule
export def "employer-pay-schedule-employees GetEmployeesFromPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Employees")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from a pay schedule on effective date.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Employees/{EffectiveDate}
# operationId: GetEmployeesFromPayScheduleOnEffectiveDate
export def "employer-pay-schedule-employees GetEmployeesFromPayScheduleOnEffectiveDate" [
  EmployerId: string
  PayScheduleId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Employees/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay run
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: DeletePayRun
export def "employer-pay-schedule-pay-run DeletePayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay run from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}
# operationId: GetPayRunFromPaySchedule
export def "employer-pay-schedule-pay-run GetPayRunFromPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<PayRun: record<Executed: string, IsSupplementary: bool, PayFrequency: string, PaySchedule: record<_href: string, _rel: string, _title: string>, PaymentDate: string, PeriodEnd: string, PeriodStart: string, ProceedingPayRun: record<_href: string, _rel: string, _title: string>, Sequence: int, TaxPeriod: int, TaxYear: int>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the auto enrolment assessments
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/AEAssessments
# operationId: GetAEAssessmentsFromPayRun
export def "employer-pay-schedule-pay-run-ae-assessments GetAEAssessmentsFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/AEAssessments")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to all commentaries for the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Commentaries
# operationId: GetCommentariesFromPayRun
export def "employer-pay-schedule-pay-run-commentaries GetCommentariesFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Commentaries")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a pay run employee
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}
# operationId: DeletePayRunEmployee
export def "employer-pay-schedule-pay-run-employee DeletePayRunEmployee" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Employee/($EmployeeId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get commentary from payrun by specified employee.
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employee/{EmployeeId}/Commentary
# operationId: GetCommentaryFromPayRunByEmployee
export def "employer-pay-schedule-pay-run-employee-commentary GetCommentaryFromPayRunByEmployee" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  EmployeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Commentary: record<Created: string, Detail: string, Employee: record<_href: string, _rel: string, _title: string>, PayRun: record<_href: string, _rel: string, _title: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Employee/($EmployeeId)/Commentary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employees from the pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Employees
# operationId: GetEmployeesFromPayRun
export def "employer-pay-schedule-pay-run-employees GetEmployeesFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Employees")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/JournalLines
# operationId: GetJournalLinesFromPayRun
export def "employer-pay-schedule-pay-run-journal-lines GetJournalLinesFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/JournalLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/PayLines
# operationId: GetPayLinesFromPayRun
export def "employer-pay-schedule-pay-run-pay-lines GetPayLinesFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/PayLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the report lines from the specified pay run
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/ReportLines
# operationId: GetReportLinesFromPayRun
export def "employer-pay-schedule-pay-run-report-lines GetReportLinesFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/ReportLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay run tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: DeletePayRunTag
export def "employer-pay-schedule-pay-run-tag DeletePayRunTag" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay run tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: GetTagFromPayRun
export def "employer-pay-schedule-pay-run-tag GetTagFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay run tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tag/{TagId}
# operationId: PutPayRunTag
export def "employer-pay-schedule-pay-run-tag PutPayRunTag" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRun/{PayRunId}/Tags
# operationId: GetTagsFromPayRun
export def "employer-pay-schedule-pay-run-tags GetTagsFromPayRun" [
  EmployerId: string
  PayScheduleId: string
  PayRunId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRun/($PayRunId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay runs from the pay schedule
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns
# operationId: GetPayRunsFromPaySchedule
export def "employer-pay-schedule-pay-runs GetPayRunsFromPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRuns")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay runs with tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tag/{TagId}
# operationId: GetPayRunsWithTag
export def "employer-pay-schedule-pay-runs-tag GetPayRunsWithTag" [
  EmployerId: string
  PayScheduleId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRuns/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay run tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/PayRuns/Tags
# operationId: GetAllPayRunTags
export def "employer-pay-schedule-pay-runs-tags GetAllPayRunTags" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/PayRuns/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete pay schedule tag
#
# DELETE /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: DeletePayScheduleTag
export def "employer-pay-schedule-tag DeletePayScheduleTag" [
  EmployerId: string
  PayScheduleId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pay schedule tag
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: GetTagFromPaySchedule
export def "employer-pay-schedule-tag GetTagFromPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert pay schedule tag
#
# PUT /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tag/{TagId}
# operationId: PutPayScheduleTag
export def "employer-pay-schedule-tag PutPayScheduleTag" [
  EmployerId: string
  PayScheduleId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedule/{PayScheduleId}/Tags
# operationId: GetTagsFromPaySchedule
export def "employer-pay-schedule-tags GetTagsFromPaySchedule" [
  EmployerId: string
  PayScheduleId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedule/($PayScheduleId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pay schedule from the specified employer
#
# GET /Employer/{EmployerId}/PaySchedules
# operationId: GetPaySchedulesFromEmployer
export def "employer-pay-schedules GetPaySchedulesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedules")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pay-schedules PostPaySchedule" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PaySchedule: record # shape: {MetaData?: record, Name?: string, PayFrequency?: "Weekly"|"Monthly"|"TwoWeekly"|"FourWeekly"|"Yearly"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedules")
  let body = {PaySchedule: $PaySchedule} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pay schedule with tag
#
# GET /Employer/{EmployerId}/PaySchedules/Tag/{TagId}
# operationId: GetPaySchedulesWithTag
export def "employer-pay-schedules-tag GetPaySchedulesWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedules/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pay schedule tags
#
# GET /Employer/{EmployerId}/PaySchedules/Tags
# operationId: GetAllPayScheduleTags
export def "employer-pay-schedules-tags GetAllPayScheduleTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/PaySchedules/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a Pension
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}
# operationId: DeletePension
export def "employer-pension DeletePension" [
  EmployerId: string
  PensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pension from employer
#
# GET /Employer/{EmployerId}/Pension/{PensionId}
# operationId: GetPensionFromEmployer
export def "employer-pension GetPensionFromEmployer" [
  EmployerId: string
  PensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pension PatchPension" [
  EmployerId: string
  PensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)")
  let body = {Pension: $Pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pension PutPensionIntoEmployer" [
  EmployerId: string
  PensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)")
  let body = {Pension: $Pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Pension revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: DeletePensionRevisionByNumber
export def "employer-pension-revision DeletePensionRevisionByNumber" [
  EmployerId: string
  PensionId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the pension by revision number
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revision/{RevisionNumber}
# operationId: GetPensionRevisionByNumber
export def "employer-pension-revision GetPensionRevisionByNumber" [
  EmployerId: string
  PensionId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all pension revisions
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/Revisions
# operationId: GetPensionRevisions
export def "employer-pension-revisions GetPensionRevisions" [
  EmployerId: string
  PensionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Pension revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: DeletePensionRevision
export def "employer-pension DeletePensionRevision" [
  EmployerId: string
  PensionId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pension by effective date.
#
# GET /Employer/{EmployerId}/Pension/{PensionId}/{EffectiveDate}
# operationId: GetPensionByEffectiveDate
export def "employer-pension GetPensionByEffectiveDate" [
  EmployerId: string
  PensionId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Pension: record<AECompatible: bool, Certification: string, Code: string, ContributionDeductionDay: int, EffectiveDate: string, EmployeeContributionCash: float, EmployeeContributionPercent: float, EmployerContributionCash: float, EmployerContributionPercent: float, EmployerNiSaving: bool, EmployerNiSavingPercentage: float, Group: string, LowerThreshold: float, MetaData: record, NextRevisionDate: string, PensionablePayCodes: record<PayCode: list>, ProRataMethod: string, ProviderEmployerRef: string, ProviderName: string, QualifyingPayCodes: record<PayCode: list>, RasRoundingOverride: string, Revision: int, RoundingOption: string, SalarySacrifice: bool, SchemeName: string, SubGroup: string, TaxationMethod: string, UpperThreshold: float, UseAEThresholds: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pension/($PensionId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get pensions from employer.
#
# GET /Employer/{EmployerId}/Pensions
# operationId: GetPensionsFromEmployer
export def "employer-pensions GetPensionsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pensions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-pensions PostPensionIntoEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Pension: record # shape: {AECompatible?: bool, Certification?: "NotSet"|"Set1"|"Set2"|"Set3", Code?: string, ContributionDeductionDay?: int, EffectiveDate?: string, EmployeeContributionCash?: float, EmployeeContributionPercent?: float, EmployerContributionCash?: float, EmployerContributionPercent?: float, EmployerNiSaving?: bool, EmployerNiSavingPercentage?: float, Group?: string, LowerThreshold?: float, MetaData?: record, NextRevisionDate?: string, PensionablePayCodes?: record, ProRataMethod?: "NotSet"|"Annual260Days"|"Annual365Days"|"AnnualQualifyingDays"|"DaysPerCalendarMonth"|"DaysPerTaxPeriod"|"WorkingDaysPerCalendarMonth"|"WeekDaysPerCalendarMonth", ProviderEmployerRef?: string, ProviderName?: string, QualifyingPayCodes?: record, RasRoundingOverride?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", Revision?: int, RoundingOption?: "NotSet"|"PennyUp"|"PennyDown"|"Bankers"|"FiveUp"|"FiveDown"|"Floor"|"Ceiling", SalarySacrifice?: bool, SchemeName?: string, SubGroup?: string, TaxationMethod?: "NotSet"|"NetBased"|"ReliefAtSource"|"TaxReliefExcluded", UpperThreshold?: float, UseAEThresholds?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pensions")
  let body = {Pension: $Pension} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get pensions from employer at a given effective date.
#
# GET /Employer/{EmployerId}/Pensions/{EffectiveDate}
# operationId: GetPensionsByEffectiveDate
export def "employer-pensions GetPensionsByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Pensions/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified report line from the employer
#
# GET /Employer/{EmployerId}/ReportLine/{ReportLineId}
# operationId: GetReportLineFromEmployer
export def "employer-report-line GetReportLineFromEmployer" [
  EmployerId: string
  ReportLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportLine: record<Description: string, Generated: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportLine/($ReportLineId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the report lines from the specified employer
#
# GET /Employer/{EmployerId}/ReportLines
# operationId: GetReportLinesFromEmployer
export def "employer-report-lines GetReportLinesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a reporting instruction
#
# DELETE /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: DeleteReportingInstruction
export def "employer-reporting-instruction DeleteReportingInstruction" [
  EmployerId: string
  ReportingInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportingInstruction/($ReportingInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the specified reporting instruction from the employer
#
# GET /Employer/{EmployerId}/ReportingInstruction/{ReportingInstructionId}
# operationId: GetReportingInstructionFromEmployer
export def "employer-reporting-instruction GetReportingInstructionFromEmployer" [
  EmployerId: string
  ReportingInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportingInstruction/($ReportingInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-reporting-instruction PutReportingInstruction" [
  EmployerId: string
  ReportingInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ReportingInstruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<ReportingInstruction: record<EndDate: string, StartDate: string, TaxMonth: int, TaxYear: int, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportingInstruction/($ReportingInstructionId)")
  let body = {ReportingInstruction: $ReportingInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the reporting instructions from the specified employer
#
# GET /Employer/{EmployerId}/ReportingInstructions
# operationId: GetReportingInstructionsFromEmployer
export def "employer-reporting-instructions GetReportingInstructionsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportingInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-reporting-instructions PostReportingInstruction" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ReportingInstruction: record # shape: {EndDate?: string, StartDate?: string, TaxMonth?: int, TaxYear?: int, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ReportingInstructions")
  let body = {ReportingInstruction: $ReportingInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an Employer revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: DeleteEmployerRevisionByNumber
export def "employer-revision DeleteEmployerRevisionByNumber" [
  EmployerId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}
# operationId: GetEmployerRevisionByNumber
export def "employer-revision GetEmployerRevisionByNumber" [
  EmployerId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer summary by revision number
#
# GET /Employer/{EmployerId}/Revision/{RevisionNumber}/Summary
# operationId: GetEmployerRevisionSummaryByNumber
export def "employer-revision-summary GetEmployerRevisionSummaryByNumber" [
  EmployerId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Revision/($RevisionNumber)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer revisions
#
# GET /Employer/{EmployerId}/Revisions
# operationId: GetEmployerRevisions
export def "employer-revisions GetEmployerRevisions" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer revision summaries
#
# GET /Employer/{EmployerId}/Revisions/Summary
# operationId: GetEmployerRevisionSummaries
export def "employer-revisions-summary GetEmployerRevisionSummaries" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Revisions/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete the RTI transaction
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: DeleteRtiTransaction
export def "employer-rti-transaction DeleteRtiTransaction" [
  EmployerId: string
  RtiTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}
# operationId: GetRtiTransactionFromEmployer
export def "employer-rti-transaction GetRtiTransactionFromEmployer" [
  EmployerId: string
  RtiTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI transaction summary
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Summary
# operationId: GetRtiTransactionSummaryFromEmployer
export def "employer-rti-transaction-summary GetRtiTransactionSummaryFromEmployer" [
  EmployerId: string
  RtiTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<RtiTransactionBase: record<EmployerCore: record<_href: string, _rel: string, _title: string>, RequestData: string, ResponseData: string, RtiType: string, TaxYear: int, Timestamp: string, TransactionStatus: string, TransmissionDate: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete RTI transaction tag
#
# DELETE /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: DeleteRtiTransactionTag
export def "employer-rti-transaction-tag DeleteRtiTransactionTag" [
  EmployerId: string
  RtiTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get RTI transaction tag
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: GetTagFromRtiTransaction
export def "employer-rti-transaction-tag GetTagFromRtiTransaction" [
  EmployerId: string
  RtiTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert RTI transaction tag
#
# PUT /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tag/{TagId}
# operationId: PutRtiTransactionTag
export def "employer-rti-transaction-tag PutRtiTransactionTag" [
  EmployerId: string
  RtiTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from RTI transaction
#
# GET /Employer/{EmployerId}/RtiTransaction/{RtiTransactionId}/Tags
# operationId: GetTagsFromRtiTransaction
export def "employer-rti-transaction-tags GetTagsFromRtiTransaction" [
  EmployerId: string
  RtiTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransaction/($RtiTransactionId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transactions for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions
# operationId: GetRtiTransactionsFromEmployer
export def "employer-rti-transactions GetRtiTransactionsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransactions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transaction summaries for the employer
#
# GET /Employer/{EmployerId}/RtiTransactions/Summary
# operationId: GetRtiTransactionSummariesFromEmployer
export def "employer-rti-transactions-summary GetRtiTransactionSummariesFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransactions/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get RTI transactions with tag
#
# GET /Employer/{EmployerId}/RtiTransactions/Tag/{TagId}
# operationId: GetRtiTransactionsWithTag
export def "employer-rti-transactions-tag GetRtiTransactionsWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransactions/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI transaction tags
#
# GET /Employer/{EmployerId}/RtiTransactions/Tags
# operationId: GetAllRtiTransactionTags
export def "employer-rti-transactions-tags GetAllRtiTransactionTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/RtiTransactions/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes employer secret
#
# DELETE /Employer/{EmployerId}/Secret/{SecretId}
# operationId: DeleteEmployerSecret
export def "employer-secret DeleteEmployerSecret" [
  EmployerId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer secret
#
# GET /Employer/{EmployerId}/Secret/{SecretId}
# operationId: GetEmployerSecret
export def "employer-secret GetEmployerSecret" [
  EmployerId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employer secret
#
# PUT /Employer/{EmployerId}/Secret/{SecretId}
# operationId: PutEmployerSecret
export def "employer-secret PutEmployerSecret" [
  EmployerId: string
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<EmployerSecret: record<Created: string, Name: string, Value: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer secret links
#
# GET /Employer/{EmployerId}/Secrets
# operationId: GetEmployerSecrets
export def "employer-secrets GetEmployerSecrets" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new employer secret
#
# POST /Employer/{EmployerId}/Secrets
# operationId: PostEmployerSecret
export def "employer-secrets PostEmployerSecret" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an sub contractor
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: DeleteSubContractor
export def "employer-sub-contractor DeleteSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor from employer
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}
# operationId: GetSubContractorFromEmployer
export def "employer-sub-contractor GetSubContractorFromEmployer" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-sub-contractor PatchSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --SubContractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)")
  let body = {SubContractor: $SubContractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-sub-contractor PutSubContractorIntoEmployer" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --SubContractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)")
  let body = {SubContractor: $SubContractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a CIS instruction
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: DeleteCisInstruction
export def "employer-sub-contractor-cis-instruction DeleteCisInstruction" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instruction from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: GetCisInstructionFromSubContractor
export def "employer-sub-contractor-cis-instruction GetCisInstructionFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patches the CIS instruction
#
# PATCH /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}
# operationId: PatchCisInstruction
export def "employer-sub-contractor-cis-instruction PatchCisInstruction" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-sub-contractor-cis-instruction PutCisInstructionIntoSubContractor" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --CisInstruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<CisInstruction: record<CisLineTag: string, CisLineType: string, Description: string, PayFrequency: string, PeriodEnd: int, PeriodStart: int, TaxYearEnd: int, TaxYearStart: int, UOM: string, Units: float, VAT: float, Value: float>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)")
  let body = {CisInstruction: $CisInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete CIS instruction tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: DeleteCisInstructionTag
export def "employer-sub-contractor-cis-instruction-tag DeleteCisInstructionTag" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instruction tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: GetTagFromCisInstruction
export def "employer-sub-contractor-cis-instruction-tag GetTagFromCisInstruction" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS instruction tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tag/{TagId}
# operationId: PutCisInstructionTag
export def "employer-sub-contractor-cis-instruction-tag PutCisInstructionTag" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS instruction
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstruction/{CisInstructionId}/Tags
# operationId: GetTagsFromCisInstruction
export def "employer-sub-contractor-cis-instruction-tags GetTagsFromCisInstruction" [
  EmployerId: string
  SubContractorId: string
  CisInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstruction/($CisInstructionId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS instructions from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions
# operationId: GetCisInstructionsFromSubContractor
export def "employer-sub-contractor-cis-instructions GetCisInstructionsFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-sub-contractor-cis-instructions PostCisInstructionIntoSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --CisInstruction: record # shape: {CisLineTag?: string, CisLineType?: string, Description?: string, PayFrequency?: "Monthly"|"Weekly", PeriodEnd?: int, PeriodStart?: int, TaxYearEnd?: int, TaxYearStart?: int, UOM?: "NotSet"|"Minute"|"Hour"|"Day"|"Week"|"Month"|"Year"|"Unit", Units?: float, VAT?: float, Value?: float}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstructions")
  let body = {CisInstruction: $CisInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get CIS instructions with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tag/{TagId}
# operationId: GetCisInstructionsWithTag
export def "employer-sub-contractor-cis-instructions-tag GetCisInstructionsWithTag" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstructions/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS instruction tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisInstructions/Tags
# operationId: GetAllCisInstructionTags
export def "employer-sub-contractor-cis-instructions-tags GetAllCisInstructionTags" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisInstructions/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete a CIS line
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: DeleteCisLine
export def "employer-sub-contractor-cis-line DeleteCisLine" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line from sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}
# operationId: GetCisLineFromSubContractor
export def "employer-sub-contractor-cis-line GetCisLineFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<CisLine: record<CisDeduction: float, CisLineType: string, Description: string, Generated: string, GrossPay: float, NominalCodeKey: string, PayFrequency: string, TaxMonth: int, TaxPeriod: int, TaxTreatment: string, TaxYear: int, UOM: string, UnitRate: float, Units: float, VAT: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete CIS line tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: DeleteCisLineTag
export def "employer-sub-contractor-cis-line-tag DeleteCisLineTag" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS line tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: GetTagFromCisLine
export def "employer-sub-contractor-cis-line-tag GetTagFromCisLine" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert CIS line tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tag/{TagId}
# operationId: PutCisLineTag
export def "employer-sub-contractor-cis-line-tag PutCisLineTag" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the CIS line
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLine/{CisLineId}/Tags
# operationId: GetTagsFromCisLine
export def "employer-sub-contractor-cis-line-tags GetTagsFromCisLine" [
  EmployerId: string
  SubContractorId: string
  CisLineId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLine/($CisLineId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS lines from sub contractor.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines
# operationId: GetCisLinesFromSubContractor
export def "employer-sub-contractor-cis-lines GetCisLinesFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get CIS lines with tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tag/{TagId}
# operationId: GetCisLinesWithTag
export def "employer-sub-contractor-cis-lines-tag GetCisLinesWithTag" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLines/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS line tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/CisLines/Tags
# operationId: GetAllCisLineTags
export def "employer-sub-contractor-cis-lines-tags GetAllCisLineTags" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/CisLines/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the journal Lines from the specified sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/JournalLines
# operationId: GetJournalLinesFromSubContractor
export def "employer-sub-contractor-journal-lines GetJournalLinesFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/JournalLines")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an SubContractor revision matching the specified revision number.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: DeleteSubContractorRevisionByNumber
export def "employer-sub-contractor-revision DeleteSubContractorRevisionByNumber" [
  EmployerId: string
  SubContractorId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the sub contractor by revision number
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revision/{RevisionNumber}
# operationId: GetSubContractorRevisionByNumber
export def "employer-sub-contractor-revision GetSubContractorRevisionByNumber" [
  EmployerId: string
  SubContractorId: string
  RevisionNumber: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Revision/($RevisionNumber)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor revisions
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Revisions
# operationId: GetSubContractorRevisions
export def "employer-sub-contractor-revisions GetSubContractorRevisions" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Revisions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete sub contractor tag
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: DeleteSubContractorTag
export def "employer-sub-contractor-tag DeleteSubContractorTag" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: GetTagFromSubContractor
export def "employer-sub-contractor-tag GetTagFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert sub contractor tag
#
# PUT /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}
# operationId: PutSubContractorTag
export def "employer-sub-contractor-tag PutSubContractorTag" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor revision tag
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromSubContractorRevision
export def "employer-sub-contractor-tag GetTagFromSubContractorRevision" [
  EmployerId: string
  SubContractorId: string
  TagId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tag/($TagId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all tags from the sub contractor
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags
# operationId: GetTagsFromSubContractor
export def "employer-sub-contractor-tags GetTagsFromSubContractor" [
  EmployerId: string
  SubContractorId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor revision tags
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/Tags/{EffectiveDate}
# operationId: GetTagsFromSubContractorRevision
export def "employer-sub-contractor-tags GetTagsFromSubContractorRevision" [
  EmployerId: string
  SubContractorId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/Tags/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an sub contractor revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: DeleteSubContractorRevision
export def "employer-sub-contractor DeleteSubContractorRevision" [
  EmployerId: string
  SubContractorId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractor by effective date.
#
# GET /Employer/{EmployerId}/SubContractor/{SubContractorId}/{EffectiveDate}
# operationId: GetSubContractorByEffectiveDate
export def "employer-sub-contractor GetSubContractorByEffectiveDate" [
  EmployerId: string
  SubContractorId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<SubContractor: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, BusinessType: string, CompanyName: string, CompanyRegistrationNumber: string, Deactivated: bool, EffectiveDate: string, FirstName: string, Initials: string, LastName: string, MetaData: record, MiddleName: string, NextRevisionDate: string, NiNumber: string, PartnershipName: string, PartnershipUniqueTaxReference: string, PayFrequency: string, PaymentMethod: string, Region: string, Revision: int, TaxationStatus: string, Telephone: string, Territory: string, Title: string, TradingName: string, UniqueTaxReference: string, VatRegistered: bool, VatRegistrationNumber: string, VerificationDate: string, VerificationNumber: string, WorksNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractor/($SubContractorId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractors from employer.
#
# GET /Employer/{EmployerId}/SubContractors
# operationId: GetSubContractorsFromEmployer
export def "employer-sub-contractors GetSubContractorsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractors")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employer-sub-contractors PostSubContractorIntoEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --SubContractor: record # shape: {Address?: record, BankAccount?: record, BusinessType?: "SoleTrader"|"Company"|"Partnership"|"Trust", CompanyName?: string, CompanyRegistrationNumber?: string, Deactivated?: bool, EffectiveDate?: string, FirstName?: string, Initials?: string, LastName?: string, MetaData?: record, MiddleName?: string, NextRevisionDate?: string, NiNumber?: string, PartnershipName?: string, PartnershipUniqueTaxReference?: string, PayFrequency?: "Monthly"|"Weekly", PaymentMethod?: "NotSet"|"Cash"|"Cheque"|"BACS"|"FasterPayments"|"Other", Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, TaxationStatus?: "Unmatched"|"Net"|"Gross", Telephone?: string, Territory?: "UnitedKingdom", Title?: string, TradingName?: string, UniqueTaxReference?: string, VatRegistered?: bool, VatRegistrationNumber?: string, VerificationDate?: string, VerificationNumber?: string, WorksNumber?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractors")
  let body = {SubContractor: $SubContractor} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sub contractors with tag
#
# GET /Employer/{EmployerId}/SubContractors/Tag/{TagId}
# operationId: GetSubContractorsWithTag
export def "employer-sub-contractors-tag GetSubContractorsWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractors/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all sub contractor tags
#
# GET /Employer/{EmployerId}/SubContractors/Tags
# operationId: GetAllSubContractorTags
export def "employer-sub-contractors-tags GetAllSubContractorTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractors/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get sub contractors from employer at a given effective date.
#
# GET /Employer/{EmployerId}/SubContractors/{EffectiveDate}
# operationId: GetSubContractorsByEffectiveDate
export def "employer-sub-contractors GetSubContractorsByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/SubContractors/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summary
#
# GET /Employer/{EmployerId}/Summary
# operationId: GetEmployerSummary
export def "employer-summary GetEmployerSummary" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete employer tag
#
# DELETE /Employer/{EmployerId}/Tag/{TagId}
# operationId: DeleteEmployerTag
export def "employer-tag DeleteEmployerTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}
# operationId: GetTagFromEmployer
export def "employer-tag GetTagFromEmployer" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert employer tag
#
# PUT /Employer/{EmployerId}/Tag/{TagId}
# operationId: PutEmployerTag
export def "employer-tag PutEmployerTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer revision tag
#
# GET /Employer/{EmployerId}/Tag/{TagId}/{EffectiveDate}
# operationId: GetTagFromEmployerRevision
export def "employer-tag GetTagFromEmployerRevision" [
  EmployerId: string
  TagId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tag/($TagId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer tags
#
# GET /Employer/{EmployerId}/Tags
# operationId: GetTagsFromEmployer
export def "employer-tags GetTagsFromEmployer" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer revision tags
#
# GET /Employer/{EmployerId}/Tags/{EffectiveDate}
# operationId: GetTagsFromEmployerRevision
export def "employer-tags GetTagsFromEmployerRevision" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/Tags/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete third party transaction
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: DeleteThirdPartyTransaction
export def "employer-third-party-transaction DeleteThirdPartyTransaction" [
  EmployerId: string
  ThirdPartyTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}
# operationId: GetThirdPartyTransaction
export def "employer-third-party-transaction GetThirdPartyTransaction" [
  EmployerId: string
  ThirdPartyTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete third party transaction tag
#
# DELETE /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: DeleteThirdPartyTransactionTag
export def "employer-third-party-transaction-tag DeleteThirdPartyTransactionTag" [
  EmployerId: string
  ThirdPartyTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get third party transaction tag
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: GetTagFromThirdPartyTransaction
export def "employer-third-party-transaction-tag GetTagFromThirdPartyTransaction" [
  EmployerId: string
  ThirdPartyTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# insert third party transaction tag
#
# PUT /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tag/{TagId}
# operationId: PutThirdPartyTransactionTag
export def "employer-third-party-transaction-tag PutThirdPartyTransactionTag" [
  EmployerId: string
  ThirdPartyTransactionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from third party transaction
#
# GET /Employer/{EmployerId}/ThirdPartyTransaction/{ThirdPartyTransactionId}/Tags
# operationId: GetTagsFromThirdPartyTransaction
export def "employer-third-party-transaction-tags GetTagsFromThirdPartyTransaction" [
  EmployerId: string
  ThirdPartyTransactionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransaction/($ThirdPartyTransactionId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all third party transaction links
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions
# operationId: GetThirdPartyTransactions
export def "employer-third-party-transactions GetThirdPartyTransactions" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransactions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged third party transactions
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tag/{TagId}
# operationId: GetAllThirdPartyTransactionsWithTag
export def "employer-third-party-transactions-tag GetAllThirdPartyTransactionsWithTag" [
  EmployerId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransactions/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all third party transaction tags
#
# GET /Employer/{EmployerId}/ThirdPartyTransactions/Tags
# operationId: GetAllThirdPartyTransactionTags
export def "employer-third-party-transactions-tags GetAllThirdPartyTransactionTags" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/ThirdPartyTransactions/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete an Employer revision matching the specified revision date.
#
# DELETE /Employer/{EmployerId}/{EffectiveDate}
# operationId: DeleteEmployerRevision
export def "employer DeleteEmployerRevision" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the employer at the specified effective
#
# GET /Employer/{EmployerId}/{EffectiveDate}
# operationId: GetEmployerByEffectiveDate
export def "employer GetEmployerByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Employer: record<Address: record<Address1: string, Address2: string, Address3: string, Address4: string, Country: string, Postcode: string>, ApprenticeshipLevyAllowance: float, AutoEnrolment: record<Pension: record, PostponementDate: string, PrimaryAddress: record, PrimaryEmail: string, PrimaryFirstName: string, PrimaryJobTitle: string, PrimaryLastName: string, PrimaryTelephone: string, ReEnrolmentDayOffset: int, ReEnrolmentMonthOffset: int, RecentOptOutReEnrolmentExcluded: bool, SecondaryAddress: record, SecondaryEmail: string, SecondaryFirstName: string, SecondaryJobTitle: string, SecondaryLastName: string, SecondaryTelephone: string, StagingDate: string>, BacsServiceUserNumber: string, BankAccount: record<AccountName: string, AccountNumber: string, BranchName: string, Reference: string, SortCode: string>, CalculateApprenticeshipLevy: bool, ClaimEmploymentAllowance: bool, ClaimSmallEmployerRelief: bool, EffectiveDate: string, HmrcSettings: record<AccountingOfficeRef: string, COTAXRef: string, ContactEmail: string, ContactFax: string, ContactFirstName: string, ContactLastName: string, ContactTelephone: string, EmploymentAllowanceOverride: float, Password: string, SAUTR: string, Sender: string, SenderId: string, StateAidSector: string, TaxOfficeNumber: string, TaxOfficeReference: string>, MetaData: record, Name: string, NextRevisionDate: string, Region: string, Revision: int, RuleExclusions: string, Territory: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summary by effective date.
#
# GET /Employer/{EmployerId}/{EffectiveDate}/Summary
# operationId: GetEmployerSummaryByEffectiveDate
export def "employer-summary GetEmployerSummaryByEffectiveDate" [
  EmployerId: string
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employer/($EmployerId)/($EffectiveDate)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all employers
#
# GET /Employers
# operationId: GetEmployers
export def "employers GetEmployers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "employers PostEmployer" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Employer: record # shape: {Address?: record, ApprenticeshipLevyAllowance?: float, AutoEnrolment?: record, BacsServiceUserNumber?: string, BankAccount?: record, CalculateApprenticeshipLevy?: bool, ClaimEmploymentAllowance?: bool, ClaimSmallEmployerRelief?: bool, EffectiveDate?: string, HmrcSettings?: record, MetaData?: record, Name?: string, NextRevisionDate?: string, Region?: "NotSet"|"England"|"Scotland"|"Wales", Revision?: int, RuleExclusions?: "None"|"NiMissingPayInstructionRule"|"TaxMissingPayInstructionRule"|"TaxCodeUpliftRule"|"NiSetExpectedLetterRule"|"NiDateOfBirthChangeRetrospectiveCRule"|"NiDefermentStatusChangeRule"|"NiEndContractedOutTransferRule"|"PaymentAfterLeavingTaxCodeRule"|"LeaverEndInstructionsRule"|"P45StudentLoanInstructionRule"|"P45TaxInstructionRule"|"P45YtdTaxRule"|"YtdInstructionRule"|"TaxCodeRegionChangeRule"|"AutoEnrolmentStatusChangeRule"|"EmployeeDeceasedRule"|"BenefitInstructionAutoEndRule", Territory?: "UnitedKingdom"}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers")
  let body = {Employer: $Employer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get employer summaries.
#
# GET /Employers/Summary
# operationId: GetEmployerSummaries
export def "employers-summary GetEmployerSummaries" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employers with tag
#
# GET /Employers/Tag/{TagId}
# operationId: GetEmployersWithTag
export def "employers-tag GetEmployersWithTag" [
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employers/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all employer tags
#
# GET /Employers/Tags
# operationId: GetAllEmployerTags
export def "employers-tags GetAllEmployerTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Employers/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all employers at the specified effective date
#
# GET /Employers/{EffectiveDate}
# operationId: GetEmployersByEffectiveDate
export def "employers GetEmployersByEffectiveDate" [
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employers/($EffectiveDate)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employer summaries at a given effective date.
#
# GET /Employers/{EffectiveDate}/Summary
# operationId: GetEmployerSummariesByEffectiveDate
export def "employers-summary GetEmployerSummariesByEffectiveDate" [
  EffectiveDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Employers/($EffectiveDate)/Summary")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get health check status
#
# GET /Healthcheck
# operationId: GetHealthCheck
export def "healthcheck GetHealthCheck" [
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
export def "jobs-batch GetBatchJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-batch PostNewBatchJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --BatchJobInstruction: record # shape: {HoldingDate?: string, Instructions?: record, ValidateOnly?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Batch")
  let body = {BatchJobInstruction: $BatchJobInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Batch job
#
# DELETE /Jobs/Batch/{JobId}
# operationId: DeleteBatchJob
export def "jobs-batch DeleteBatchJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Batch/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job information
#
# GET /Jobs/Batch/{JobId}/Info
# operationId: GetBatchJobInfo
export def "jobs-batch-info GetBatchJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Batch/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job progress
#
# GET /Jobs/Batch/{JobId}/Progress
# operationId: GetBatchJobProgress
export def "jobs-batch-progress GetBatchJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Batch/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Batch job status
#
# GET /Jobs/Batch/{JobId}/Status
# operationId: GetBatchJobStatus
export def "jobs-batch-status GetBatchJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Batch/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all CIS jobs
#
# GET /Jobs/Cis
# operationId: GetCisJobs
export def "jobs-cis GetCisJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-cis PostNewCisJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --CisJobInstructionBase: record # shape: {Employer?: record, HoldingDate?: string, SubContractors?: record}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Cis")
  let body = {CisJobInstructionBase: $CisJobInstructionBase} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the CIS job
#
# DELETE /Jobs/Cis/{JobId}
# operationId: DeleteCisJob
export def "jobs-cis DeleteCisJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Cis/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job information
#
# GET /Jobs/Cis/{JobId}/Info
# operationId: GetCisJobInfo
export def "jobs-cis-info GetCisJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Cis/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job progress
#
# GET /Jobs/Cis/{JobId}/Progress
# operationId: GetCisJobProgress
export def "jobs-cis-progress GetCisJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Cis/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the CIS job status
#
# GET /Jobs/Cis/{JobId}/Status
# operationId: GetCisJobStatus
export def "jobs-cis-status GetCisJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Cis/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all DPS jobs
#
# GET /Jobs/Dps
# operationId: GetDpsJobs
export def "jobs-dps GetDpsJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-dps PostNewDpsJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --DpsJobInstruction: record # shape: {Apply?: bool, Employer?: record, FromDate?: string, HoldingDate?: string, MessageTypes?: record, MessagesToProcess?: record, Retrieve?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Dps")
  let body = {DpsJobInstruction: $DpsJobInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the DPS job
#
# DELETE /Jobs/Dps/{JobId}
# operationId: DeleteDpsJob
export def "jobs-dps DeleteDpsJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Dps/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job information
#
# GET /Jobs/Dps/{JobId}/Info
# operationId: GetDpsJobInfo
export def "jobs-dps-info GetDpsJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Dps/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job progress
#
# GET /Jobs/Dps/{JobId}/Progress
# operationId: GetDpsJobProgress
export def "jobs-dps-progress GetDpsJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Dps/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the DPS job status
#
# GET /Jobs/Dps/{JobId}/Status
# operationId: GetDpsJobStatus
export def "jobs-dps-status GetDpsJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Dps/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all jobs relating to the employer.
#
# GET /Jobs/Employer/{EmployerId}
# operationId: GetEmployerJobs
export def "jobs-employer GetEmployerJobs" [
  EmployerId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Employer/($EmployerId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all PayRun jobs
#
# GET /Jobs/PayRuns
# operationId: GetPayRunJobs
export def "jobs-pay-runs GetPayRunJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-pay-runs PostNewPayRunJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --PayRunJobInstruction: record # shape: {Employees?: record, EndDate?: string, HoldingDate?: string, IsSupplementary?: bool, PaySchedule?: record, PaymentDate?: string, StartDate?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/PayRuns")
  let body = {PayRunJobInstruction: $PayRunJobInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the pay run job
#
# DELETE /Jobs/PayRuns/{JobId}
# operationId: DeletePayRunJob
export def "jobs-pay-runs DeletePayRunJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/PayRuns/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job information
#
# GET /Jobs/PayRuns/{JobId}/Info
# operationId: GetPayRunJobInfo
export def "jobs-pay-runs-info GetPayRunJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/PayRuns/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job progress
#
# GET /Jobs/PayRuns/{JobId}/Progress
# operationId: GetPayRunJobProgress
export def "jobs-pay-runs-progress GetPayRunJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/PayRuns/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the pay run job status
#
# GET /Jobs/PayRuns/{JobId}/Status
# operationId: GetPayRunJobStatus
export def "jobs-pay-runs-status GetPayRunJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/PayRuns/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all RTI jobs
#
# GET /Jobs/Rti
# operationId: GetRtiJobs
export def "jobs-rti GetRtiJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-rti PostNewRtiJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --RtiJobInstruction: record # shape: {EarlierTaxYear?: int, Employer?: record, FinalSubmissionForYear?: bool, Generate?: bool, HoldingDate?: string, LateReason?: "A"|"B"|"C"|"D"|"F"|"G"|"H", NoPaymentForPeriodFrom?: string, NoPaymentForPeriodTo?: string, PaySchedule?: record, PaymentDate?: string, PeriodOfInactivityFrom?: string, PeriodOfInactivityTo?: string, RtiTransaction?: record, RtiType?: string, SchemeCeased?: string, TaxMonth?: int, TaxYear?: int, Timestamp?: string, Transmit?: bool}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/Rti")
  let body = {RtiJobInstruction: $RtiJobInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the RTI job
#
# DELETE /Jobs/Rti/{JobId}
# operationId: DeleteRtiJob
export def "jobs-rti DeleteRtiJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Rti/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job information
#
# GET /Jobs/Rti/{JobId}/Info
# operationId: GetRtiJobInfo
export def "jobs-rti-info GetRtiJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Rti/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job progress
#
# GET /Jobs/Rti/{JobId}/Progress
# operationId: GetRtiJobProgress
export def "jobs-rti-progress GetRtiJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Rti/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the RTI job status
#
# GET /Jobs/Rti/{JobId}/Status
# operationId: GetRtiJobStatus
export def "jobs-rti-status GetRtiJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/Rti/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Third Party jobs
#
# GET /Jobs/ThirdParty
# operationId: GetThirdPartyJobs
export def "jobs-third-party GetThirdPartyJobs" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "jobs-third-party PostNewThirdPartyJob" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ThirdPartyJobInstruction: record # shape: {EmployerHref?: string, HoldingDate?: string, InstructionType?: string, MetaData?: record, PayLoad?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Jobs/ThirdParty")
  let body = {ThirdPartyJobInstruction: $ThirdPartyJobInstruction} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete the Third Party job
#
# DELETE /Jobs/ThirdParty/{JobId}
# operationId: DeleteThirdPartyJob
export def "jobs-third-party DeleteThirdPartyJob" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/ThirdParty/($JobId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job information
#
# GET /Jobs/ThirdParty/{JobId}/Info
# operationId: GetThirdPartyJobInfo
export def "jobs-third-party-info GetThirdPartyJobInfo" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JobInfo: record<Created: string, EmployerKey: string, Errors: record<Error: list>, HoldingDate: string, JobId: string, JobStatus: string, JobType: string, LastUpdated: string, Progress: float>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/ThirdParty/($JobId)/Info")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job progress
#
# GET /Jobs/ThirdParty/{JobId}/Progress
# operationId: GetThirdPartyJobProgress
export def "jobs-third-party-progress GetThirdPartyJobProgress" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/ThirdParty/($JobId)/Progress")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the Third Party job status
#
# GET /Jobs/ThirdParty/{JobId}/Status
# operationId: GetThirdPartyJobStatus
export def "jobs-third-party-status GetThirdPartyJobStatus" [
  JobId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Jobs/ThirdParty/($JobId)/Status")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a Journal instruction template
#
# DELETE /JournalInstruction/{JournalInstructionId}
# operationId: DeleteJournalInstructionTemplate
export def "journal-instruction DeleteJournalInstructionTemplate" [
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions template for the application
#
# GET /JournalInstruction/{JournalInstructionId}
# operationId: GetJournalInstructionTemplate
export def "journal-instruction GetJournalInstructionTemplate" [
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a Journal Instruction template
#
# PUT /JournalInstruction/{JournalInstructionId}
# operationId: PutJournalInstructionTemplate
export def "journal-instruction PutJournalInstructionTemplate" [
  JournalInstructionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<JournalInstruction: record<AccountingType: string, Description: string, EndDate: string, Expression: string, JournalLineTag: string, LedgerTarget: string, NomCode: string, StartDate: string, SubNomCode: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/JournalInstruction/($JournalInstructionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the Journal instructions templates for the application
#
# GET /JournalInstructions
# operationId: GetJournalInstructionTemplates
export def "journal-instructions GetJournalInstructionTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Journal Instruction template
#
# POST /JournalInstructions
# operationId: PostJournalInstructionTemplate
export def "journal-instructions PostJournalInstructionTemplate" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/JournalInstructions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes the permission object
#
# DELETE /Permission/{PermissionId}
# operationId: DeletePermission
export def "permission DeletePermission" [
  PermissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the permission object
#
# GET /Permission/{PermissionId}
# operationId: GetPermission
export def "permission GetPermission" [
  PermissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch permission object
#
# PATCH /Permission/{PermissionId}
# operationId: PatchPermission
export def "permission PatchPermission" [
  PermissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts permisson object
#
# PUT /Permission/{PermissionId}
# operationId: PutPermission
export def "permission PutPermission" [
  PermissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Permission: record<Description: string, Expression: string, Name: string, Policy: string, Verbs: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Permission tag
#
# DELETE /Permission/{PermissionId}/Tag/{TagId}
# operationId: DeletePermissionTag
export def "permission-tag DeletePermissionTag" [
  PermissionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Permission tag
#
# GET /Permission/{PermissionId}/Tag/{TagId}
# operationId: GetTagFromPermission
export def "permission-tag GetTagFromPermission" [
  PermissionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert Permission tag
#
# PUT /Permission/{PermissionId}/Tag/{TagId}
# operationId: PutPermissionTag
export def "permission-tag PutPermissionTag" [
  PermissionId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from Permission
#
# GET /Permission/{PermissionId}/Tags
# operationId: GetTagsFromPermission
export def "permission-tags GetTagsFromPermission" [
  PermissionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permission/($PermissionId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all permission objects
#
# GET /Permissions
# operationId: GetPermissions
export def "permissions GetPermissions" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post permisson object
#
# POST /Permissions
# operationId: PostPermission
export def "permissions PostPermission" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged Permissions
#
# GET /Permissions/Tag/{TagId}
# operationId: GetAllPermissionsWithTag
export def "permissions-tag GetAllPermissionsWithTag" [
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Permissions/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Permission tags
#
# GET /Permissions/Tags
# operationId: GetAllPermissionTags
export def "permissions-tags GetAllPermissionTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Permissions/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "query GetQueryResponse" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --Query: record # shape: {Encoding?: string, ExcludeNullOrEmptyElements?: bool, Groups?: record, RootNodeName?: string, SuppressMetricAttributes?: bool, Variables?: record}
]: any -> string {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Query")
  let body = {Query: $Query} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the journal expression data schema
#
# GET /ReferenceData/JournalExpressionDataTable
# operationId: GetJournalExpressionSchema
export def "reference-data-journal-expression-data-table GetJournalExpressionSchema" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/ReferenceData/JournalExpressionDataTable")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the active pay instructions report
#
# GET /Report/ACTPAYINS/run
# operationId: GetActivePayInstructionsReportOutput
export def "report-actpayins-run GetActivePayInstructionsReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --EmployeeKey: string # The employee unique key. E.g. EE001
  --ActiveOn: string # The active date to consider. E.g 2017-04-05 (format: date)
  --FromDate: string # The lower filter date. E.g 2016-04-06 (format: date)
  --ToDate: string # The upper filter date. E.g 2017-04-05 (format: date)
  --Type: string # the data type to filter on. E.g. TaxPayInstruction
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "EmployeeKey" $EmployeeKey "scalar") (serialize-qp "ActiveOn" $ActiveOn "scalar") (serialize-qp "FromDate" $FromDate "scalar") (serialize-qp "ToDate" $ToDate "scalar") (serialize-qp "Type" $Type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/ACTPAYINS/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the AOE liability report
#
# GET /Report/AOELIABILITY/run
# operationId: GetAoeLiabilityReportOuput
export def "report-aoeliability-run GetAoeLiabilityReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --TaxPeriod: string # The tax period number. (format: integer)
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "TaxPeriod" $TaxPeriod "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/AOELIABILITY/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the DPS message report
#
# GET /Report/DPSMSG/run
# operationId: GetDpsMessageReportOutput
export def "report-dpsmsg-run GetDpsMessageReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --FromDate: string # The lower filter date. E.g 2016-04-06 (format: date)
  --ToDate: string # The upper filter date. E.g 2017-04-05 (format: date)
  --MessageTypes: string # The DPS message types as a CSV list. E.g. P6,P9,SL1,SL2
  --MessageStatuses: string # The DPS message status as a CSV list. E.g. Retrieved,Processed,Blocked,Ignored
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "FromDate" $FromDate "scalar") (serialize-qp "ToDate" $ToDate "scalar") (serialize-qp "MessageTypes" $MessageTypes "scalar") (serialize-qp "MessageStatuses" $MessageStatuses "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/DPSMSG/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the employer summary report
#
# GET /Report/EMPSUM/run
# operationId: GetEmployerSummaryReportOuput
export def "report-empsum-run GetEmployerSummaryReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --ContextDate: string # The date context for the report. E.g. 2018-04-30 (format: date)
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "ContextDate" $ContextDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/EMPSUM/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the gross to net report
#
# GET /Report/GRO2NET/run
# operationId: GetGrossToNetReportOutput
export def "report-gro2net-run GetGrossToNetReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --TaxPeriod: string # The tax period number. (format: integer)
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "TaxPeriod" $TaxPeriod "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/GRO2NET/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the holiday balance report
#
# GET /Report/HOLBAL/run
# operationId: GetHolidayBalanceReportOutput
export def "report-holbal-run GetHolidayBalanceReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --HolidayYearEnd: string # The holiday year end for the report. E.g. 2018-12-31 (format: date)
  --EmployeeCodes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "HolidayYearEnd" $HolidayYearEnd "scalar") (serialize-qp "EmployeeCodes" $EmployeeCodes "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/HOLBAL/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the journal report
#
# GET /Report/JOURNAL/run
# operationId: GetJournalReportOuput
export def "report-journal-run GetJournalReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayFrequency: string # The pay frequency option. E.g. Monthly
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --TaxPeriod: string # The tax period number. (format: integer)
  --LedgerTarget: string # Specific to JOURNAL report, a filter used to select the journal lines for the specified ledger target. E.g. [Default]
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayFrequency" $PayFrequency "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "TaxPeriod" $TaxPeriod "scalar") (serialize-qp "LedgerTarget" $LedgerTarget "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/JOURNAL/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the last pay date report
#
# GET /Report/LASTPAYDATE/run
# operationId: GetLastPayDateReportOuput
export def "report-lastpaydate-run GetLastPayDateReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --EmployeeKey: string # The employee unique key. E.g. EE001
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "EmployeeKey" $EmployeeKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/LASTPAYDATE/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the net pay report
#
# GET /Report/NETPAY/run
# operationId: GetNetPayReportOutput
export def "report-netpay-run GetNetPayReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --TaxPeriod: string # The tax period number. (format: integer)
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "TaxPeriod" $TaxPeriod "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NETPAY/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the next pay period report
#
# GET /Report/NEXTPERIOD/run
# operationId: GetNextPayPeriodDatesReportOutput
export def "report-nextperiod-run GetNextPayPeriodDatesReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/NEXTPERIOD/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P11 summary report
#
# GET /Report/P11SUM/run
# operationId: GetP11SummaryReportOutput
export def "report-p11sum-run GetP11SummaryReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P11SUM/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P32 report
#
# GET /Report/P32/run
# operationId: GetP32NetReportOutput
export def "report-p32-run GetP32NetReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P32 summary report
#
# GET /Report/P32SUM/run
# operationId: GetP32SummaryNetReportOutput
export def "report-p32sum-run GetP32SummaryNetReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P32SUM/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P45 report
#
# GET /Report/P45/run
# operationId: GetP45ReportOutput
export def "report-p45-run GetP45ReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --EmployeeKey: string # The employee unique key. E.g. EE001
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "EmployeeKey" $EmployeeKey "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P45/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the P60 report
#
# GET /Report/P60/run
# operationId: GetP60ReportOutput
export def "report-p60-run GetP60ReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --EmployeeCodes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "EmployeeCodes" $EmployeeCodes "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/P60/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the PAPDIS report
#
# GET /Report/PAPDIS/run
# operationId: GetPapdisReportOuput
export def "report-papdis-run GetPapdisReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --PaymentDate: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --PensionKey: string # The pension scheme unique key. E.g. PENSCH001
  --MessageFunctionCode: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar") (serialize-qp "PensionKey" $PensionKey "scalar") (serialize-qp "MessageFunctionCode" $MessageFunctionCode "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAPDIS/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the PASS report
#
# GET /Report/PASS/run
# operationId: GetPassReportOuput
export def "report-pass-run GetPassReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --PaymentDate: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --PensionKey: string # The pension scheme unique key. E.g. PENSCH001
  --MessageFunctionCode: string # Specific to PAPDIS report, specifies the business function that the sender is requesting. If left BLANK it will be assumed to be 0 (Enrol / Receive Contributions).
  --IntermediaryId: string # Specific to PensionSync PASS report, a unique identifier for the Intermediary who is acting on behalf of the employer.
  --DocumentId: string # Specific to PensionSync PASS report, a document identifier unique for this document within the Intermediary.
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar") (serialize-qp "PensionKey" $PensionKey "scalar") (serialize-qp "MessageFunctionCode" $MessageFunctionCode "scalar") (serialize-qp "IntermediaryId" $IntermediaryId "scalar") (serialize-qp "DocumentId" $DocumentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PASS/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the Pay Dashboard payslips report
#
# GET /Report/PAYDASHBOARD/run
# operationId: GetPayDashboardPayslipReportOuput
export def "report-paydashboard-run GetPayDashboardPayslipReportOuput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --EmployeeCodes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --PaymentDate: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --PublicationDate: string # Specific to the Pay Dashboard report, allows the specification of a future payslip publication date. E.g. 2018-12-31 (format: date)
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "EmployeeCodes" $EmployeeCodes "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar") (serialize-qp "PublicationDate" $PublicationDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYDASHBOARD/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the verbose payslip report
#
# GET /Report/PAYSLIP3/run
# operationId: GetPayslip3ReportOutput
export def "report-payslip3-run GetPayslip3ReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --PayScheduleKey: string # The pay schedule unique key. E.g. SCH001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --EmployeeCodes: string # A comma separated list of the employee codes. E.g. EMP001,EMP002
  --TransformDefinitionKey: string # The transform definition unique key. E.g. P45-Pdf
  --StartIndex: string # The element index to begin the report. Used to control paging within large data sets. E.g. 1
  --MaxIndex: string # The highest element index to return from the report. Used to control paging within large data sets. E.g. 100
  --PaymentDate: string # The payment date context for the report. E.g. 2018-04-30 (format: date)
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "PayScheduleKey" $PayScheduleKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "EmployeeCodes" $EmployeeCodes "scalar") (serialize-qp "TransformDefinitionKey" $TransformDefinitionKey "scalar") (serialize-qp "StartIndex" $StartIndex "scalar") (serialize-qp "MaxIndex" $MaxIndex "scalar") (serialize-qp "PaymentDate" $PaymentDate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PAYSLIP3/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Runs the pension liability report
#
# GET /Report/PENLIABILITY/run
# operationId: GetPensionLiabilityReportOutput
export def "report-penliability-run GetPensionLiabilityReportOutput" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --EmployerKey: string # The employer unique key. E.g. ER001
  --TaxYear: string # The tax year. E.g. 2017 = 2017/18 year. (format: integer)
  --PensionKey: string # The pension scheme unique key. E.g. PENSCH001
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "EmployerKey" $EmployerKey "scalar") (serialize-qp "TaxYear" $TaxYear "scalar") (serialize-qp "PensionKey" $PensionKey "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/Report/PENLIABILITY/run" $qp)
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a report definition
#
# DELETE /Report/{ReportDefinitionId}
# operationId: DeleteReportDefinition
export def "report DeleteReportDefinition" [
  ReportDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Report/($ReportDefinitionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the report definition
#
# GET /Report/{ReportDefinitionId}
# operationId: GetReportDefinitionFromApplication
export def "report GetReportDefinitionFromApplication" [
  ReportDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Report/($ReportDefinitionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "report PutReportDefinition" [
  ReportDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ReportDefinition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<ReportDefinition: record<Active: bool, Readonly: bool, ReportQuery: record<Encoding: string, ExcludeNullOrEmptyElements: bool, Groups: record, RootNodeName: string, SuppressMetricAttributes: bool, Variables: record>, SupportedTransforms: string, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Report/($ReportDefinitionId)")
  let body = {ReportDefinition: $ReportDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Runs the specified report definition
#
# GET /Report/{ReportDefinitionId}/run
# operationId: GetReportOutput
export def "report-run GetReportOutput" [
  ReportDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Report/($ReportDefinitionId)/run")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all reports
#
# GET /Reports
# operationId: GetReportDefinitionsFromApplication
export def "reports GetReportDefinitionsFromApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "reports PostReportDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --ReportDefinition: record # shape: {Active?: bool, Readonly?: bool, ReportQuery?: record, SupportedTransforms?: string, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Reports")
  let body = {ReportDefinition: $ReportDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of all available schemas
#
# GET /Schemas
# operationId: GetSchemas
export def "schemas GetSchemas" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Schemas")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get XSD schema
#
# GET /Schemas/{DtoDataType}
# operationId: GetSchema
export def "schemas GetSchema" [
  DtoDataType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Schemas/($DtoDataType)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes Application secret
#
# DELETE /Secret/{SecretId}
# operationId: DeleteApplicationSecret
export def "secret DeleteApplicationSecret" [
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Application secret
#
# GET /Secret/{SecretId}
# operationId: GetApplicationSecret
export def "secret GetApplicationSecret" [
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Application secret
#
# PUT /Secret/{SecretId}
# operationId: PutApplicationSecret
export def "secret PutApplicationSecret" [
  SecretId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Secret/($SecretId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all Application secret links
#
# GET /Secrets
# operationId: GetApplicationSecrets
export def "secrets GetApplicationSecrets" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a new Application secret
#
# POST /Secrets
# operationId: PostApplicationSecret
export def "secrets PostApplicationSecret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Secrets")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the object template
#
# GET /Template/{DtoDataType}
# operationId: GetTemplateModel
export def "template GetTemplateModel" [
  DtoDataType: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Template/($DtoDataType)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of all available data object tempaltes
#
# GET /Templates
# operationId: GetTemplates
export def "templates GetTemplates" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Templates")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a transform definition
#
# DELETE /Transform/{TransformDefinitionId}
# operationId: DeleteTransformDefinition
export def "transform DeleteTransformDefinition" [
  TransformDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Transform/($TransformDefinitionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the transform definition
#
# GET /Transform/{TransformDefinitionId}
# operationId: GetTransformDefinitionFromApplication
export def "transform GetTransformDefinitionFromApplication" [
  TransformDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Transform/($TransformDefinitionId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "transform PutTransformDefinition" [
  TransformDefinitionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --TransformDefinition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<TransformDefinition: record<Active: bool, ContentType: string, Definition: string, DefinitionType: string, Readonly: bool, SupportedReports: string, TaxYear: int, Title: string, Version: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Transform/($TransformDefinitionId)")
  let body = {TransformDefinition: $TransformDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets all transform definitions
#
# GET /Transforms
# operationId: GetTransformDefinitionsFromApplication
export def "transforms GetTransformDefinitionsFromApplication" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
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
export def "transforms PostTransformDefinition" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
  --TransformDefinition: record # shape: {Active?: bool, ContentType?: string, Definition?: string, DefinitionType?: string, Readonly?: bool, SupportedReports?: string, TaxYear?: int, Title?: string, Version?: string}
]: any -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Transforms")
  let body = {TransformDefinition: $TransformDefinition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Deletes the user object
#
# DELETE /User/{UserId}
# operationId: DeleteUser
export def "user DeleteUser" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user object
#
# GET /User/{UserId}
# operationId: GetUser
export def "user GetUser" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch user object
#
# PATCH /User/{UserId}
# operationId: PatchUser
export def "user PatchUser" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Puts user object
#
# PUT /User/{UserId}
# operationId: PutUser
export def "user PutUser" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<User: record<MetaData: record, Permissions: record<Permission: list>, Roles: record<Role: list>, UserIdentifier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the user permissions
#
# GET /User/{UserId}/Permissions
# operationId: GetUserPermissions
export def "user-permissions GetUserPermissions" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)/Permissions")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete user tag
#
# DELETE /User/{UserId}/Tag/{TagId}
# operationId: DeleteUserTag
export def "user-tag DeleteUserTag" [
  UserId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get user tag
#
# GET /User/{UserId}/Tag/{TagId}
# operationId: GetTagFromUser
export def "user-tag GetTagFromUser" [
  UserId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Insert user tag
#
# PUT /User/{UserId}/Tag/{TagId}
# operationId: PutUserTag
export def "user-tag PutUserTag" [
  UserId: string
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Tag: record<Created: string, TaggedItem: record<_href: string, _rel: string, _title: string>, Text: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get tags from user
#
# GET /User/{UserId}/Tags
# operationId: GetTagsFromUser
export def "user-tags GetTagsFromUser" [
  UserId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/User/($UserId)/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all user objects
#
# GET /Users
# operationId: GetUsers
export def "users GetUsers" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Post user object
#
# POST /Users
# operationId: PostUser
export def "users PostUser" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<Link: record<_href: string, _rel: string, _title: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get links to tagged users
#
# GET /Users/Tag/{TagId}
# operationId: GetAllUsersWithTag
export def "users-tag GetAllUsersWithTag" [
  TagId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/Users/Tag/($TagId)")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get all user tags
#
# GET /Users/Tags
# operationId: GetAllUserTags
export def "users-tags GetAllUserTags" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # The OAuth 1 authorization header. &apos;Auto&apos; enables auto complete.
  --Api-Version: string # The version of the api to target. Omit or set as &apos;default&apos; to target the current api version.
]: nothing -> record<LinkCollection: record<Links: record<Link: list>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/Users/Tags")
  let extra_headers = {"Authorization": $Authorization, "Api-Version": $Api_Version} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
