# Auto-generated client for Paylocity API v2
# Source: https://api.apis.guru/v2/specs/paylocity.com/2/openapi.json
# Auth: --token flag or $env.PAYLOCITY_API_TOKEN

const BASE_URL = "https://api.paylocity.com/api"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o PAYLOCITY_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://api.paylocity.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-codes Get-All-Company-Codes-and-Descriptions-by-Resource" } } | get name | first)
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

# Get All Company Codes
#
# GET /v2/companies/{companyId}/codes/{codeResource}
# operationId: Get All Company Codes and Descriptions by Resource
export def "companies-codes Get-All-Company-Codes-and-Descriptions-by-Resource" [
  companyId: string
  codeResource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/codes/($codeResource)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Custom Fields
#
# GET /v2/companies/{companyId}/customfields/{category}
# operationId: Get All Custom Fields by category
export def "companies-customfields Get-All-Custom-Fields-by-category" [
  companyId: string
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, defaultValue: string, isRequired: bool, label: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/customfields/($category)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new employee
#
# POST /v2/companies/{companyId}/employees
# operationId: Add employee
# --additionalDirectDeposit item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
# --additionalRate item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
# --benefitSetup shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
# --customBooleanFields item shape: {category: "PayrollAndHR", label: string, value: bool}
# --customDateFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customDropDownFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customNumberFields item shape: {category: "PayrollAndHR", label: string, value: float}
# --customTextFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --departmentPosition shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
# --emergencyContacts item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
# --federalTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
# --homeAddress shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
# --localTax item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
# --mainDirectDeposit shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
# --nonPrimaryStateTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --primaryPayRate shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
# --primaryStateTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --status shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
# --taxSetup shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
# --webTime shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
# --workAddress shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
# --workEligibility shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
export def "companies-employees Add-employee" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalDirectDeposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additionalRate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefitSetup: record #  Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birthDate: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --coEmpCode: string # Unique idenifier for SSO.<br  />Max length: 20 (nullable)
  --companyFEIN: string # Company FEIN as defined in Web Pay, applicable with GET requests only.<br  /> Max length: 20 (nullable)
  --companyName: string # Company name as defined in Web Pay, applicable with GET requests only.<br  /> Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. <br  />Max length: 30 (nullable)
  --customBooleanFields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --customDateFields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customDropDownFields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customNumberFields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --customTextFields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --departmentPosition: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
  --disabilityDescription: string # Indicates if employee has disability status. (nullable)
  --emergencyContacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --employeeId: string # Leave blank to have Web Pay automatically assign the next available employee ID.<br  />Max length: 9 (nullable)
  --ethnicity: string # Employee ethnicity.<br  /> Max length: 10 (nullable)
  --federalTax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --firstName: string # Employee first name. <br  />Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). <br  />Max length: 1 (nullable)
  --homeAddress: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --isHighlyCompensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --isSmoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --lastName: string # Employee last name. <br  />Max length: 40 (nullable)
  --localTax: list # Add, update, or delete local tax code, filing status, and exemptions including  PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --mainDirectDeposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --maritalStatus: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. <br  />Max length: 10 (nullable)
  --middleName: string # Employee middle name.<br  /> Max length: 20 (nullable)
  --nonPrimaryStateTax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --ownerPercent: float # Percentage of employee's ownership in the company, entered as a whole number. <br  /> Decimal (12,2) (nullable)
  --preferredName: string # Employee preferred display name.<br  /> Max length: 20 (nullable)
  --primaryPayRate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primaryStateTax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --priorLastName: string # Prior last name if applicable.<br  />Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. <br  />Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. <br  />Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.<br  />Max length: 30 (nullable)
  --taxSetup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteranDescription: string # Indicates if employee is a veteran. (nullable)
  --webTime: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --workAddress: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --workEligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> record<employeeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees")
  let body = {additionalDirectDeposit: $additionalDirectDeposit, additionalRate: $additionalRate, benefitSetup: $benefitSetup, birthDate: $birthDate, coEmpCode: $coEmpCode, companyFEIN: $companyFEIN, companyName: $companyName, currency: $currency, customBooleanFields: $customBooleanFields, customDateFields: $customDateFields, customDropDownFields: $customDropDownFields, customNumberFields: $customNumberFields, customTextFields: $customTextFields, departmentPosition: $departmentPosition, disabilityDescription: $disabilityDescription, emergencyContacts: $emergencyContacts, employeeId: $employeeId, ethnicity: $ethnicity, federalTax: $federalTax, firstName: $firstName, gender: $gender, homeAddress: $homeAddress, isHighlyCompensated: $isHighlyCompensated, isSmoker: $isSmoker, lastName: $lastName, localTax: $localTax, mainDirectDeposit: $mainDirectDeposit, maritalStatus: $maritalStatus, middleName: $middleName, nonPrimaryStateTax: $nonPrimaryStateTax, ownerPercent: $ownerPercent, preferredName: $preferredName, primaryPayRate: $primaryPayRate, primaryStateTax: $primaryStateTax, priorLastName: $priorLastName, salutation: $salutation, ssn: $ssn, status: $status, suffix: $suffix, taxSetup: $taxSetup, veteranDescription: $veteranDescription, webTime: $webTime, workAddress: $workAddress, workEligibility: $workEligibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all employees
#
# GET /v2/companies/{companyId}/employees/
# operationId: Get all employees
export def "companies-employees Get-all-employees" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
]: nothing -> table<employeeId: string, statusCode: string, statusTypeCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee
#
# GET /v2/companies/{companyId}/employees/{employeeId}
# operationId: Get employee
export def "companies-employees Get-employee" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalDirectDeposit: table<accountNumber: string, accountType: string, amount: float, amountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, additionalRate: table<changeReason: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, endCheckDate: string, job: string, rate: float, rateCode: string, rateNotes: string, ratePer: string, shift: string>, benefitSetup: record<benefitClass: string, benefitClassEffectiveDate: string, benefitSalary: float, benefitSalaryEffectiveDate: string, doNotApplyAdministrativePeriod: bool, isMeasureAcaEligibility: bool>, birthDate: string, coEmpCode: string, companyFEIN: string, companyName: string, currency: string, customBooleanFields: table<category: string, label: string, value: bool>, customDateFields: table<category: string, label: string, value: string>, customDropDownFields: table<category: string, label: string, value: string>, customNumberFields: table<category: string, label: string, value: float>, customTextFields: table<category: string, label: string, value: string>, departmentPosition: record<changeReason: string, clockBadgeNumber: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, employeeType: string, equalEmploymentOpportunityClass: string, isMinimumWageExempt: bool, isOvertimeExempt: bool, isSupervisorReviewer: bool, isUnionDuesCollected: bool, isUnionInitiationCollected: bool, jobTitle: string, payGroup: string, positionCode: string, reviewerCompanyNumber: string, reviewerEmployeeId: string, shift: string, supervisorCompanyNumber: string, supervisorEmployeeId: string, tipped: string, unionAffiliationDate: string, unionCode: string, unionPosition: string, workersCompensation: string>, disabilityDescription: string, emergencyContacts: table<address1: string, address2: string, city: string, country: string, county: string, email: string, firstName: string, homePhone: string, lastName: string, mobilePhone: string, notes: string, pager: string, primaryPhone: string, priority: string, relationship: string, state: string, syncEmployeeInfo: bool, workExtension: string, workPhone: string, zip: string>, employeeId: string, ethnicity: string, federalTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, taxCalculationCode: string, w4FormYear: int>, firstName: string, gender: string, homeAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, mobilePhone: string, phone: string, postalCode: string, state: string>, isHighlyCompensated: bool, isSmoker: bool, lastName: string, localTax: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, maritalStatus: string, middleName: string, nonPrimaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, reciprocityCode: string, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, ownerPercent: float, preferredName: string, primaryPayRate: record<annualSalary: float, baseRate: float, beginCheckDate: string, changeReason: string, defaultHours: float, effectiveDate: string, isAutoPay: bool, payFrequency: string, payGrade: string, payRateNote: string, payType: string, ratePer: string, salary: float>, primaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, priorLastName: string, salutation: string, ssn: string, status: record<adjustedSeniorityDate: string, changeReason: string, effectiveDate: string, employeeStatus: string, hireDate: string, isEligibleForRehire: bool, reHireDate: string, statusType: string, terminationDate: string>, suffix: string, taxSetup: record<fitwExemptNotes: string, fitwExemptReason: string, futaExemptNotes: string, futaExemptReason: string, isEmployee943: bool, isPension: bool, isStatutory: bool, medExemptNotes: string, medExemptReason: string, sitwExemptNotes: string, sitwExemptReason: string, ssExemptNotes: string, ssExemptReason: string, suiExemptNotes: string, suiExemptReason: string, suiState: string, taxDistributionCode1099R: string, taxForm: string>, veteranDescription: string, webTime: record<badgeNumber: string, chargeRate: float, isTimeLaborEnabled: bool>, workAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, location: string, mailStop: string, mobilePhone: string, pager: string, phone: string, phoneExtension: string, postalCode: string, state: string>, workEligibility: record<alienOrAdmissionDocumentNumber: string, attestedDate: string, countryOfIssuance: string, foreignPassportNumber: string, i94AdmissionNumber: string, i9DateVerified: string, i9Notes: string, isI9Verified: bool, isSsnVerified: bool, ssnDateVerified: string, ssnNotes: string, visaType: string, workAuthorization: string, workUntil: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update employee
#
# PATCH /v2/companies/{companyId}/employees/{employeeId}
# operationId: Update employee
# --additionalDirectDeposit item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
# --additionalRate item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
# --benefitSetup shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
# --customBooleanFields item shape: {category: "PayrollAndHR", label: string, value: bool}
# --customDateFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customDropDownFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customNumberFields item shape: {category: "PayrollAndHR", label: string, value: float}
# --customTextFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --departmentPosition shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
# --emergencyContacts item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
# --federalTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
# --homeAddress shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
# --localTax item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
# --mainDirectDeposit shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
# --nonPrimaryStateTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --primaryPayRate shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
# --primaryStateTax shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --status shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
# --taxSetup shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
# --webTime shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
# --workAddress shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
# --workEligibility shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
export def "companies-employees Update-employee" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalDirectDeposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additionalRate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefitSetup: record #  Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birthDate: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --coEmpCode: string # Unique idenifier for SSO.<br  />Max length: 20 (nullable)
  --companyFEIN: string # Company FEIN as defined in Web Pay, applicable with GET requests only.<br  /> Max length: 20 (nullable)
  --companyName: string # Company name as defined in Web Pay, applicable with GET requests only.<br  /> Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. <br  />Max length: 30 (nullable)
  --customBooleanFields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --customDateFields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customDropDownFields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customNumberFields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --customTextFields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --departmentPosition: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
  --disabilityDescription: string # Indicates if employee has disability status. (nullable)
  --emergencyContacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --body-employeeId: string # Leave blank to have Web Pay automatically assign the next available employee ID.<br  />Max length: 9 (nullable)
  --ethnicity: string # Employee ethnicity.<br  /> Max length: 10 (nullable)
  --federalTax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --firstName: string # Employee first name. <br  />Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). <br  />Max length: 1 (nullable)
  --homeAddress: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --isHighlyCompensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --isSmoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --lastName: string # Employee last name. <br  />Max length: 40 (nullable)
  --localTax: list # Add, update, or delete local tax code, filing status, and exemptions including  PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --mainDirectDeposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --maritalStatus: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. <br  />Max length: 10 (nullable)
  --middleName: string # Employee middle name.<br  /> Max length: 20 (nullable)
  --nonPrimaryStateTax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --ownerPercent: float # Percentage of employee's ownership in the company, entered as a whole number. <br  /> Decimal (12,2) (nullable)
  --preferredName: string # Employee preferred display name.<br  /> Max length: 20 (nullable)
  --primaryPayRate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primaryStateTax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --priorLastName: string # Prior last name if applicable.<br  />Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. <br  />Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. <br  />Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.<br  />Max length: 30 (nullable)
  --taxSetup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteranDescription: string # Indicates if employee is a veteran. (nullable)
  --webTime: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --workAddress: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --workEligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)")
  let body = {additionalDirectDeposit: $additionalDirectDeposit, additionalRate: $additionalRate, benefitSetup: $benefitSetup, birthDate: $birthDate, coEmpCode: $coEmpCode, companyFEIN: $companyFEIN, companyName: $companyName, currency: $currency, customBooleanFields: $customBooleanFields, customDateFields: $customDateFields, customDropDownFields: $customDropDownFields, customNumberFields: $customNumberFields, customTextFields: $customTextFields, departmentPosition: $departmentPosition, disabilityDescription: $disabilityDescription, emergencyContacts: $emergencyContacts, employeeId: $body_employeeId, ethnicity: $ethnicity, federalTax: $federalTax, firstName: $firstName, gender: $gender, homeAddress: $homeAddress, isHighlyCompensated: $isHighlyCompensated, isSmoker: $isSmoker, lastName: $lastName, localTax: $localTax, mainDirectDeposit: $mainDirectDeposit, maritalStatus: $maritalStatus, middleName: $middleName, nonPrimaryStateTax: $nonPrimaryStateTax, ownerPercent: $ownerPercent, preferredName: $preferredName, primaryPayRate: $primaryPayRate, primaryStateTax: $primaryStateTax, priorLastName: $priorLastName, salutation: $salutation, ssn: $ssn, status: $status, suffix: $suffix, taxSetup: $taxSetup, veteranDescription: $veteranDescription, webTime: $webTime, workAddress: $workAddress, workEligibility: $workEligibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add/update additional rates
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/additionalRates
# operationId: Add or update additional rates
export def "companies-employees-additional-rates Add-or-update-additional-rates" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --changeReason: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Change Reason drop down.<br /> (nullable)
  --costCenter1: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 1 drop down. This cell must be in a text format.<br /> (nullable)
  --costCenter2: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 2 drop down. This cell must be in a text format.<br /> (nullable)
  --costCenter3: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 3 drop down. This cell must be in a text format.<br /> (nullable)
  --effectiveDate: string # Required. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*.<br /> (nullable, format: paylocity-date)
  --endCheckDate: string # Not required. Must match one of the system coded check dates available in the Additional Rates End Check Date drop down. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*.<br /> (nullable, format: paylocity-date)
  --job: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Job drop down.<br /> (nullable)
  --rate: float # Required. Enter dollar amount that corresponds to the Per selection.<br /> (nullable)
  --rateCode: string # Required. If populated, must match one of the system coded values available in the Additional Rates Rate Code drop down.<br /> (nullable)
  --rateNotes: string # Not required.<br  />Max length: 4000<br /> (nullable)
  --ratePer: string # Required. Valid values are HOUR or WEEK.<br /> (nullable)
  --shift: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Shift drop down.<br /> (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/additionalRates")
  let body = {changeReason: $changeReason, costCenter1: $costCenter1, costCenter2: $costCenter2, costCenter3: $costCenter3, effectiveDate: $effectiveDate, endCheckDate: $endCheckDate, job: $job, rate: $rate, rateCode: $rateCode, rateNotes: $rateNotes, ratePer: $ratePer, shift: $shift} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add/update employee's benefit setup
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/benefitSetup
# operationId: Update or add employee benefit setup
export def "companies-employees-benefit-setup Update-or-add-employee-benefit-setup" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --benefitClass: string # Benefit Class code. Values are configured in Web Pay Company > Setup > Benefits > Classes.<br  />Max length: 30 (nullable)
  --benefitClassEffectiveDate: string # Date when Benefit Class takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --benefitSalary: float # Salary used to configure benefits.<br  />Decimal(12,2) (nullable)
  --benefitSalaryEffectiveDate: string # Date when Benefit Salary takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --doNotApplyAdministrativePeriod: oneof<nothing, bool> # Applicable only for HR Enhanced clients and Benefit Classes with ACA Employment Type of Full Time. (nullable)
  --isMeasureAcaEligibility: oneof<nothing, bool> # Only valid for HR Enhanced clients and Benefit Classes that are ACA Employment Type of Full Time. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/benefitSetup")
  let body = {benefitClass: $benefitClass, benefitClassEffectiveDate: $benefitClassEffectiveDate, benefitSalary: $benefitSalary, benefitSalaryEffectiveDate: $benefitSalaryEffectiveDate, doNotApplyAdministrativePeriod: $doNotApplyAdministrativePeriod, isMeasureAcaEligibility: $isMeasureAcaEligibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get All Direct Deposit
#
# GET /v2/companies/{companyId}/employees/{employeeId}/directDeposit
# operationId: Get All Direct Deposit
export def "companies-employees-direct-deposit Get-All-Direct-Deposit" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<additionalDirectDeposit: list<record>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/directDeposit")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get All Earnings
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings
# operationId: Get All Earnings
export def "companies-employees-earnings Get-All-Earnings" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/earnings")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/Update Earning
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/earnings
# operationId: Add or update an employee earning
export def "companies-employees-earnings Add-or-update-an-employee-earning" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --agency: string # Third-party agency associated with earning. Must match Company setup.<br  />Max length: 10 (nullable)
  --amount: float # Value that matches CalculationCode to add to gross wages. For percentage (%), enter whole number (10 = 10%).  <br  />Decimal(12,2) (nullable)
  --annualMaximum: float # Year to Date dollar amount not to be exceeded for an earning in the calendar year. Used only with company driven maximums. <br  />Decimal(12,2) (nullable)
  --calculationCode: string # Defines how earnings are calculated. Common values are *% (percentage of gross), flat (flat dollar amount)*. Defaulted to the Company setup calcCode for earning. <br  />Max length: 20 (nullable)
  --costCenter1: string # Cost Center associated with earning. Must match Company setup.<br  /> Max length: 10 (nullable)
  --costCenter2: string # Cost Center associated with earning. Must match Company setup.<br  /> Max length: 10 (nullable)
  --costCenter3: string # Cost Center associated with earning. Must match Company setup.<br  /> Max length: 10 (nullable)
  --earningCode: string # Earning code. Must match Company setup. <br  />Max length: 10 (nullable)
  --effectiveDate: string # Date earning is active. Defaulted to run date or check date based on Company setup. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --endDate: string # Stop date of an earning. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --frequency: string # Needed if earning is applied differently from the payroll frequency (one time earning for example).<br  /> Max length: 5 (nullable)
  --goal: float # Dollar amount. The employee earning will stop when the goal amount is reached.<br  /> Decimal(12,2) (nullable)
  --hoursOrUnits: float # The value is used in conjunction with the Rate field. When entering Group Term Life Insurance (GTL), it should contain the full amount of the group term life insurance policy. <br  /> Decimal(12,2) (nullable)
  --isSelfInsured: oneof<nothing, bool> # Used for ACA. If not entered, defaulted to Company earning setup. (nullable)
  --jobCode: string # Job code associated with earnings. Must match Company setup.<br  /> Max length: 20 (nullable)
  --miscellaneousInfo: string # Information to print on the check stub if agency is set up for this earning. <br  />Max length: 50 (nullable)
  --paidTowardsGoal: float # Amount already paid to employee toward goal. <br  /> Decimal(12,2) (nullable)
  --payPeriodMaximum: float # Maximum amount of the earning on a single paycheck. <br  /> Decimal(12,2) (nullable)
  --payPeriodMinimum: float # Minimum amount of the earning on a single paycheck. <br  /> Decimal(12,2) (nullable)
  --rate: float # Rate is used in conjunction with the hoursOrUnits field. <br  /> Decimal(12,2) (nullable)
  --rateCode: string # Rate Code applies to additional pay rates entered for an employee. Must match Company setup. <br  /> Max length: 10 (nullable)
  --startDate: string # Start date of an earning based on payroll calendar. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/earnings")
  let body = {agency: $agency, amount: $amount, annualMaximum: $annualMaximum, calculationCode: $calculationCode, costCenter1: $costCenter1, costCenter2: $costCenter2, costCenter3: $costCenter3, earningCode: $earningCode, effectiveDate: $effectiveDate, endDate: $endDate, frequency: $frequency, goal: $goal, hoursOrUnits: $hoursOrUnits, isSelfInsured: $isSelfInsured, jobCode: $jobCode, miscellaneousInfo: $miscellaneousInfo, paidTowardsGoal: $paidTowardsGoal, payPeriodMaximum: $payPeriodMaximum, payPeriodMinimum: $payPeriodMinimum, rate: $rate, rateCode: $rateCode, startDate: $startDate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Earnings by Earning Code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}
# operationId: Get Earnings by Earning Code
export def "companies-employees-earnings Get-Earnings-by-Earning-Code" [
  companyId: string
  employeeId: string
  earningCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/earnings/($earningCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Earning by Earning Code and Start Date
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# operationId: Delete Earning by Earning Code and Start Date
export def "companies-employees-earnings Delete-Earning-by-Earning-Code-and-Start-Date" [
  companyId: string
  employeeId: string
  earningCode: string
  startDate: string
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
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/earnings/($earningCode)/($startDate)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Earning by Earning Code and Start Date
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# operationId: Get Earning by Earning Code and Start Date
export def "companies-employees-earnings Get-Earning-by-Earning-Code-and-Start-Date" [
  companyId: string
  employeeId: string
  earningCode: string
  startDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/earnings/($earningCode)/($startDate)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/update emergency contacts
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/emergencyContacts
# operationId: Add or update emergency contacts
export def "companies-employees-emergency-contacts Add-or-update-emergency-contacts" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # 1st address line. (nullable)
  --address2: string # 2nd address line. (nullable)
  --city: string # City. (nullable)
  --country: string # County. (nullable)
  --county: string # Country.  Must be a valid 3 character country code.  Common values are *USA* (United States), *CAN* (Canada). (nullable)
  --email: string # Contact email.  Must be valid email address format. (nullable)
  --firstName: string # Required. Contact first name. <br  />Max length: 40 (nullable)
  --homePhone: string # Contact Home Phone.  Valid phone format  *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --lastName: string # Required. Contact last name. <br  />Max length: 40 (nullable)
  --mobilePhone: string # Contact Mobile Phone.  Valid phone format  *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --notes: string # Notes. <br  />Max length: 1000 (nullable)
  --pager: string # Contact Pager.  Valid phone format  *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --primaryPhone: string # Required. Contact primary phone type.  Must match Company setup.  Valid  values are H (Home), M (Mobile), P (Pager), W (Work) (nullable)
  --priority: string # Required. Contact priority. Valid values are *P* (Primary) or *S* (Secondary). (nullable)
  --relationship: string # Required. Contact relationship.  Must match Company setup.  Common values are Spouse, Mother, Father. (nullable)
  --state: string # State or Province.  If U.S. address, must be valid 2 character state code.  Common values are *IL* (Illinois), *CA* (California). (nullable)
  --syncEmployeeInfo: oneof<nothing, bool> # Valid values are *true* or *false*.
  --workExtension: string # Work Extension. (nullable)
  --workPhone: string # Contact Work Phone.  Valid phone format  *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --zip: string # Postal code.  If U.S. address, must be a valid zip code. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/emergencyContacts")
  let body = {address1: $address1, address2: $address2, city: $city, country: $country, county: $county, email: $email, firstName: $firstName, homePhone: $homePhone, lastName: $lastName, mobilePhone: $mobilePhone, notes: $notes, pager: $pager, primaryPhone: $primaryPhone, priority: $priority, relationship: $relationship, state: $state, syncEmployeeInfo: $syncEmployeeInfo, workExtension: $workExtension, workPhone: $workPhone, zip: $zip} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all local taxes
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# operationId: Get all local taxes
export def "companies-employees-local-taxes Get-all-local-taxes" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/localTaxes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add new local tax
#
# POST /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# operationId: Add local tax
export def "companies-employees-local-taxes Add-local-tax" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --exemptions: float # Local tax exemptions value.<br  />Decimal (12,2) (nullable)
  --exemptions2: float # Local tax exemptions 2 value.<br  />Decimal (12,2) (nullable)
  --filingStatus: string # Employee local tax filing status. Must match specific local tax setup. <br  /> Max length: 50 (nullable)
  --residentPSD: string # Resident PSD (political subdivision code) applicable in PA. Must match Company setup.<br  /> Max length: 9 (nullable)
  --taxCode: string # Local tax code.<br  />Max length: 50 (nullable)
  --workPSD: string # Work location PSD. Must match Company setup. <br  /> Max length: 9 (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/localTaxes")
  let body = {exemptions: $exemptions, exemptions2: $exemptions2, filingStatus: $filingStatus, residentPSD: $residentPSD, taxCode: $taxCode, workPSD: $workPSD} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete local tax by tax code
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# operationId: Delete local tax by tax code
export def "companies-employees-local-taxes Delete-local-tax-by-tax-code" [
  companyId: string
  employeeId: string
  taxCode: string
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
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/localTaxes/($taxCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get local taxes by tax code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# operationId: Get local tax by tax code
export def "companies-employees-local-taxes Get-local-tax-by-tax-code" [
  companyId: string
  employeeId: string
  taxCode: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/localTaxes/($taxCode)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/update non-primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/nonprimaryStateTax
# operationId: Add or update non-primary state tax
export def "companies-employees-nonprimary-state-tax Add-or-update-non-primary-state-tax" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code.<br  /> Max length: 50 (nullable)
  --deductionsAmount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. <br  />Decimal (12,2)
  --dependentsAmount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. <br  />Decimal (12,2)
  --exemptions: float # State tax exemptions value.<br  />Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.<br  />Decimal (12,2) (nullable)
  --filingStatus: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).<br  />Max length: 50 (nullable)
  --higherRate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. <br  />Boolean
  --otherIncomeAmount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. <br  />Decimal (12,2)
  --percentage: float # State Tax percentage. <br  />Decimal (12,2) (nullable)
  --reciprocityCode: string # Non-primary state tax reciprocity code.<br  /> Max length: 50 (nullable)
  --specialCheckCalc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). <br  />Max length: 10 (nullable)
  --taxCalculationCode: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). <br  />Max length: 10 (nullable)
  --taxCode: string # State tax code.<br  /> Max length: 50 (nullable)
  --w4FormYear: int # The state W4 form year <br  />Integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/nonprimaryStateTax")
  let body = {amount: $amount, deductionsAmount: $deductionsAmount, dependentsAmount: $dependentsAmount, exemptions: $exemptions, exemptions2: $exemptions2, filingStatus: $filingStatus, higherRate: $higherRate, otherIncomeAmount: $otherIncomeAmount, percentage: $percentage, reciprocityCode: $reciprocityCode, specialCheckCalc: $specialCheckCalc, taxCalculationCode: $taxCalculationCode, taxCode: $taxCode, w4FormYear: $w4FormYear} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get employee pay statement details data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}
# operationId: Gets employee pay statement detail data based on the specified year
export def "companies-employees-paystatement-details Gets-employee-pay-statement-detail-data-based-on-the-specified-year" [
  companyId: string
  employeeId: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/paystatement/details/($year)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee pay statement details data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}/{checkDate}
# operationId: Gets employee pay statement detail data based on the specified year and check date
export def "companies-employees-paystatement-details Gets-employee-pay-statement-detail-data-based-on-the-specified-year-and-check-date" [
  companyId: string
  employeeId: string
  year: string
  checkDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/paystatement/details/($year)/($checkDate)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee pay statement summary data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}
# operationId: Gets employee pay statement summary data based on the specified year
export def "companies-employees-paystatement-summary Gets-employee-pay-statement-summary-data-based-on-the-specified-year" [
  companyId: string
  employeeId: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/paystatement/summary/($year)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get employee pay statement summary data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}/{checkDate}
# operationId: Gets employee pay statement summary data based on the specified year and check date
export def "companies-employees-paystatement-summary Gets-employee-pay-statement-summary-data-based-on-the-specified-year-and-check-date" [
  companyId: string
  employeeId: string
  year: string
  checkDate: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/paystatement/summary/($year)/($checkDate)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/update primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/primaryStateTax
# operationId: Add or update primary state tax
export def "companies-employees-primary-state-tax Add-or-update-primary-state-tax" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code.<br  /> Max length: 50 (nullable)
  --deductionsAmount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. <br  />Decimal (12,2)
  --dependentsAmount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. <br  />Decimal (12,2)
  --exemptions: float # State tax exemptions value.<br  />Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.<br  />Decimal (12,2) (nullable)
  --filingStatus: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).<br  />Max length: 50 (nullable)
  --higherRate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. <br  />Boolean
  --otherIncomeAmount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. <br  />Decimal (12,2)
  --percentage: float # State Tax percentage. <br  />Decimal (12,2) (nullable)
  --specialCheckCalc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). <br  />Max length: 10 (nullable)
  --taxCalculationCode: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). <br  />Max length: 10 (nullable)
  --taxCode: string # State tax code.<br  /> Max length: 50 (nullable)
  --w4FormYear: int # The state W4 form year <br  />Integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/primaryStateTax")
  let body = {amount: $amount, deductionsAmount: $deductionsAmount, dependentsAmount: $dependentsAmount, exemptions: $exemptions, exemptions2: $exemptions2, filingStatus: $filingStatus, higherRate: $higherRate, otherIncomeAmount: $otherIncomeAmount, percentage: $percentage, specialCheckCalc: $specialCheckCalc, taxCalculationCode: $taxCalculationCode, taxCode: $taxCode, w4FormYear: $w4FormYear} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get sensitive data
#
# GET /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# operationId: Get sensitive data
export def "companies-employees-sensitivedata Get-sensitive-data" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<disability: record<disability: string, disabilityClassifications: list, hasDisability: string>, ethnicity: record<ethnicRacialIdentities: list, ethnicity: string>, gender: record<displayPronouns: bool, genderIdentityDescription: string, identifyAsLegalGender: string, legalGender: string, pronouns: string, sexualOrientation: string>, veteran: record<isVeteran: string, veteran: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/sensitivedata")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add/update sensitive data
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# operationId: Add or update Sensitive Data
# --disability shape: {disability?: string, disabilityClassifications?: list, hasDisability?: string}
# --ethnicity shape: {ethnicRacialIdentities?: list, ethnicity?: string}
# --gender shape: {displayPronouns?: bool, genderIdentityDescription?: string, identifyAsLegalGender?: string, legalGender?: string, pronouns?: string, sexualOrientation?: string}
# --veteran shape: {isVeteran?: string, veteran?: string}
export def "companies-employees-sensitivedata Add-or-update-Sensitive-Data" [
  companyId: string
  employeeId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --disability: record # Add or update disability data. — shape: {disability?: string, disabilityClassifications?: list, hasDisability?: string}
  --ethnicity: record # Add or update ethnicity data. — shape: {ethnicRacialIdentities?: list, ethnicity?: string}
  --gender: record # Add or update gender data. — shape: {displayPronouns?: bool, genderIdentityDescription?: string, identifyAsLegalGender?: string, legalGender?: string, pronouns?: string, sexualOrientation?: string}
  --veteran: record # Add or update veteran data. — shape: {isVeteran?: string, veteran?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/employees/($employeeId)/sensitivedata")
  let body = {disability: $disability, ethnicity: $ethnicity, gender: $gender, veteran: $veteran} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Company-Specific Open API Documentation
#
# GET /v2/companies/{companyId}/openapi
# operationId: Get company-specific Open API documentation
export def "companies-openapi Get-company-specific-Open-API-documentation" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --Authorization: string # Bearer + JWT
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/companies/($companyId)/openapi")
  let extra_headers = {"Authorization": $Authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Obtain new client secret.
#
# POST /v2/credentials/secrets
# operationId: Add Client Secret
export def "credentials-secrets Add-Client-Secret" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # A value sent with the 'ACTION NEEDED: Web Link API Credentials Expiring Soon.' email notification.
]: any -> table<clientSecret: string, clientSecretExpirationDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/credentials/secrets")
  let body = {code: $code} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add new employee to Web Link
#
# POST /v2/weblinkstaging/companies/{companyId}/employees/newemployees
# operationId: Add new employee to Web Link
# --additionalDirectDeposit item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
# --benefitSetup item shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
# --customBooleanFields item shape: {category: "PayrollAndHR", label: string, value: bool}
# --customDateFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customDropDownFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --customNumberFields item shape: {category: "PayrollAndHR", label: string, value: float}
# --customTextFields item shape: {category: "PayrollAndHR", label: string, value: string}
# --departmentPosition item shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
# --federalTax item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
# --homeAddress item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
# --localTax item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
# --mainDirectDeposit item shape: {accountNumber?: string, accountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
# --nonPrimaryStateTax item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --primaryPayRate item shape: {baseRate?: float, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payType?: string, ratePer?: string, salary?: float}
# --primaryStateTax item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
# --status item shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool}
# --webTime shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
# --workAddress item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
# --workEligibility item shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
export def "weblinkstaging-companies-employees-newemployees Add-new-employee-to-Web-Link" [
  companyId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --additionalDirectDeposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --benefitSetup: list # Add setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — item shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birthDate: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --customBooleanFields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --customDateFields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customDropDownFields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --customNumberFields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --customTextFields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --departmentPosition: list # Add home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — item shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, tipped?: string, unionAffiliationDate?: string, unionCode?: string, unionPosition?: string, workersCompensation?: string}
  --disabilityDescription: string # Indicates if employee has disability status. (nullable)
  --employeeId: string # Leave blank to have Web Pay automatically assign the next available employee ID.<br  /> Max length: 10 (nullable)
  --ethnicity: string # Employee ethnicity.<br  /> Max length: 10 (nullable)
  --federalTax: list # Add federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --firstName: string # Employee first name. <br  />Max length: 40 (nullable)
  --fitwExemptReason: string # Reason code for FITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). <br  /> Max length: 30 (nullable)
  --futaExemptReason: string # Reason code for FUTA exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor).<br  /> Max length: 30 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). <br  />Max length: 1 (nullable)
  --homeAddress: list # Add employee's home address, personal phone numbers, and personal email. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --isEmployee943: oneof<nothing, bool> # Indicates if employee in agriculture or farming. (nullable)
  --isSmoker: oneof<nothing, bool> # Indicates if employee is a smoker. (nullable)
  --lastName: string # Employee last name. <br  />Max length: 40 (nullable)
  --localTax: list # Add local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --mainDirectDeposit: list # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --maritalStatus: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. <br  />Max length: 10 (nullable)
  --medExemptReason: string # Reason code for Medicare exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor).<br  /> Max length: 30 (nullable)
  --middleName: string # Employee middle name.<br  /> Max length: 20 (nullable)
  --nonPrimaryStateTax: list # Add non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --preferredName: string # Employee preferred display name.<br  /> Max length: 20 (nullable)
  --primaryPayRate: list # Add hourly or salary pay rate, effective date, and pay frequency. — item shape: {baseRate?: float, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payType?: string, ratePer?: string, salary?: float}
  --primaryStateTax: list # Add primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --priorLastName: string # Prior last name if applicable.<br  />Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. <br  />Max length: 10 (nullable)
  --sitwExemptReason: string # Reason code for SITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). <br  /> Max length: 30 (nullable)
  --ssExemptReason: string # Reason code for Social Security exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). <br  /> Max length: 30 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. <br  />Max length: 11 (nullable)
  --status: list # Add employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — item shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.<br  />Max length: 30 (nullable)
  --suiExemptReason: string # Reason code for SUI exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). <br  /> Max length: 30 (nullable)
  --suiState: string # Employee SUI (State Unemployment Insurance) state. <br  />Max length: 2 (nullable)
  --taxDistributionCode1099R: string # Employee 1099R distribution code. Common values are *7* (Normal Distribution), *F* (Charitable Gift Annuity). <br  />Max length: 1 (nullable)
  --taxForm: string # Employee tax form for reporting income. Valid values are *W2, 1099M, 1099R*. Default is W2. <br  />Max length: 15 (nullable)
  --veteranDescription: string # Indicates if employee is a veteran. (nullable)
  --webTime: record # Add Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --workAddress: list # Add employee's work address, phone numbers, and email. Work Location drop down field is not included. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --workEligibility: list # Add I-9 work authorization information. — item shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> table<trackingNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/v2/weblinkstaging/companies/($companyId)/employees/newemployees")
  let body = {additionalDirectDeposit: $additionalDirectDeposit, benefitSetup: $benefitSetup, birthDate: $birthDate, customBooleanFields: $customBooleanFields, customDateFields: $customDateFields, customDropDownFields: $customDropDownFields, customNumberFields: $customNumberFields, customTextFields: $customTextFields, departmentPosition: $departmentPosition, disabilityDescription: $disabilityDescription, employeeId: $employeeId, ethnicity: $ethnicity, federalTax: $federalTax, firstName: $firstName, fitwExemptReason: $fitwExemptReason, futaExemptReason: $futaExemptReason, gender: $gender, homeAddress: $homeAddress, isEmployee943: $isEmployee943, isSmoker: $isSmoker, lastName: $lastName, localTax: $localTax, mainDirectDeposit: $mainDirectDeposit, maritalStatus: $maritalStatus, medExemptReason: $medExemptReason, middleName: $middleName, nonPrimaryStateTax: $nonPrimaryStateTax, preferredName: $preferredName, primaryPayRate: $primaryPayRate, primaryStateTax: $primaryStateTax, priorLastName: $priorLastName, salutation: $salutation, sitwExemptReason: $sitwExemptReason, ssExemptReason: $ssExemptReason, ssn: $ssn, status: $status, suffix: $suffix, suiExemptReason: $suiExemptReason, suiState: $suiState, taxDistributionCode1099R: $taxDistributionCode1099R, taxForm: $taxForm, veteranDescription: $veteranDescription, webTime: $webTime, workAddress: $workAddress, workEligibility: $workEligibility} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
