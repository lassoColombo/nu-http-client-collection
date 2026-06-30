# Auto-generated client for Paylocity API v2
# Source: https://api.apis.guru/v2/specs/paylocity.com/2/openapi.json
# Auth: --token flag or $env.PAYLOCITY_API_TOKEN

const BASE_URL = "https://api.paylocity.com/api"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token | is-not-empty) { $token } else { $env | get -o PAYLOCITY_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "bearer" => { {scheme: $scheme, headers: {Authorization: $"Bearer ($token_val)"}, query: "", location: "header"} }
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
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
}

# Serialize an array-typed path parameter. OpenAPI 3 `style: simple`
# (the default for path params) and Swagger 2 `collectionFormat: csv` both join
# the elements with a literal comma WITHIN the single path segment, each element
# RFC-3986-encoded individually (so a comma inside an element stays %2C). Without
# this a `list` positional would render as the Nushell debug form `[a, b]`,
# producing a guaranteed-404 URL. The else-branch keeps scalar values on the
# historical encode-path-segment path (defensive against a bare string).
def encode-path-array [v: any]: nothing -> string {
  if (($v | describe) | str starts-with "list") { $v | each { encode-path-segment $in } | str join "," } else { encode-path-segment $v }
}

# Build the request URL from base, path, and any number of pre-encoded query
# fragments (param serializer output and/or the auth query). Each fragment is an
# `&`-joinable `key=value` string already percent-encoded by its producer; empty
# fragments are dropped. `url parse`/`url join` own the `?`/`&` structure — no
# delimiters are hand-spliced — and any query already on the base URL is merged in.
def build-url [base: string, path: string, ...query_parts: string]: nothing -> string {
  let parsed = ($base | url parse | reject params)
  let full_path = if ($path | is-empty) { $parsed.path } else { [$parsed.path $path] | str join "/" | str replace --all --regex '/+' '/' }
  let query = ([$parsed.query] | append $query_parts | where {|q| $q | is-not-empty } | str join "&")
  $parsed | upsert path $full_path | upsert query $query | url join
}

# Success policy: did this response succeed? Single source of truth, consulted by
# handle-response and the HEAD header-unwrap. Empty ok_codes means the spec listed
# none, so fall back to < 400. Otherwise: any 2xx, plus documented success codes.
def status-ok [status: int, ok_codes: list<int>]: nothing -> bool {
  if ($ok_codes | is-empty) { $status < 400 } else { ($status >= 200 and $status < 300) or ($status in $ok_codes) }
}

# Unwrap a `--full` HTTP response into the user-facing value. Response arrives
# via pipeline; ok_codes gates the error throw (see status-ok).
def handle-response [allow_errors: bool, full: bool, ok_codes: list<int>]: record -> any {
  let resp = $in
  if $allow_errors { return $resp }
  if not (status-ok $resp.status $ok_codes) { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } }
  if $full { return {status: $resp.status, headers: $resp.headers, body: $resp.body} }
  if $resp.status == 204 { return null }
  $resp.body
}

# GET — bodyless, honours --raw
def send-get [req: record, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  http get --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url | handle-response $allow_errors $full $ok_codes
}

# POST — body + content-type
def send-post [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http post --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http post --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PUT — body + content-type
def send-put [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http put --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http put --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# PATCH — body + content-type
def send-patch [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http patch --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url "" } else { http patch --headers $req.headers --content-type $req.content_type --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url $body }
  $resp | handle-response $allow_errors $full $ok_codes
}

# DELETE — body via --data
def send-delete [req: record, body: any, insecure: bool, raw: bool, allow_errors: bool, full: bool, ok_codes: list<int>]: nothing -> any {
  let resp = if ($body | is-empty) { http delete --headers $req.headers --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url } else { http delete --headers $req.headers --content-type $req.content_type --data $body --full --allow-errors --max-time $req.timeout --insecure=$insecure --raw=$raw $req.url }
  $resp | handle-response $allow_errors $full $ok_codes
}

def base-url-completer [] { ["https://api.paylocity.com/api"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "companies-codes get-list-company-and-descriptions-by-resource" } } | get name | first)
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
export def "companies-codes get-list-company-and-descriptions-by-resource" [
  company_id: string
  code_resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<code: string, description: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($code_resource | is-empty) { error make --unspanned { msg: "path parameter 'codeResource' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), code_resource: (encode-path-segment $code_resource)} | format pattern "/v2/companies/{company_id}/codes/{code_resource}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get All Custom Fields
#
# GET /v2/companies/{companyId}/customfields/{category}
# operationId: Get All Custom Fields by category
export def "companies-customfields get-list-custom-fields" [
  company_id: string
  category: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<category: string, defaultValue: string, isRequired: bool, label: string, type: string, values: list<record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($category | is-empty) { error make --unspanned { msg: "path parameter 'category' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), category: (encode-path-segment $category)} | format pattern "/v2/companies/{company_id}/customfields/{category}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
# --departmentPosition shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
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
export def "companies-employees create" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additional-rate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefit-setup: record # Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --co-emp-code: string # Unique idenifier for SSO.Max length: 20 (nullable)
  --company-fein: string # Company FEIN as defined in Web Pay, applicable with GET requests only. Max length: 20 (nullable)
  --company-name: string # Company name as defined in Web Pay, applicable with GET requests only. Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. Max length: 30 (nullable)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --emergency-contacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID.Max length: 9 (nullable)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-highly-compensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add, update, or delete local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --owner-percent: float # Percentage of employee's ownership in the company, entered as a whole number. Decimal (12,2) (nullable)
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --tax-setup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> record<employeeId: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v2/companies/{company_id}/employees") $auth.query)
  let req_body = {"additionalDirectDeposit": $additional_direct_deposit, "additionalRate": $additional_rate, "benefitSetup": $benefit_setup, "birthDate": $birth_date, "coEmpCode": $co_emp_code, "companyFEIN": $company_fein, "companyName": $company_name, "currency": $currency, "customBooleanFields": $custom_boolean_fields, "customDateFields": $custom_date_fields, "customDropDownFields": $custom_drop_down_fields, "customNumberFields": $custom_number_fields, "customTextFields": $custom_text_fields, "departmentPosition": $department_position, "disabilityDescription": $disability_description, "emergencyContacts": $emergency_contacts, "employeeId": $employee_id, "ethnicity": $ethnicity, "federalTax": $federal_tax, "firstName": $first_name, "gender": $gender, "homeAddress": $home_address, "isHighlyCompensated": $is_highly_compensated, "isSmoker": $is_smoker, "lastName": $last_name, "localTax": $local_tax, "mainDirectDeposit": $main_direct_deposit, "maritalStatus": $marital_status, "middleName": $middle_name, "nonPrimaryStateTax": $non_primary_state_tax, "ownerPercent": $owner_percent, "preferredName": $preferred_name, "primaryPayRate": $primary_pay_rate, "primaryStateTax": $primary_state_tax, "priorLastName": $prior_last_name, "salutation": $salutation, "ssn": $ssn, "status": $status, "suffix": $suffix, "taxSetup": $tax_setup, "veteranDescription": $veteran_description, "webTime": $web_time, "workAddress": $work_address, "workEligibility": $work_eligibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Get all employees
#
# GET /v2/companies/{companyId}/employees/
# operationId: Get all employees
export def "companies-employees get-list" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
]: nothing -> table<employeeId: string, statusCode: string, statusTypeCode: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v2/companies/{company_id}/employees/") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenumber": $pagenumber, "includetotalcount": $includetotalcount} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get employee
#
# GET /v2/companies/{companyId}/employees/{employeeId}
# operationId: Get employee
export def "companies-employees get" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<additionalDirectDeposit: table<accountNumber: string, accountType: string, amount: float, amountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, additionalRate: table<changeReason: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, endCheckDate: string, job: string, rate: float, rateCode: string, rateNotes: string, ratePer: string, shift: string>, benefitSetup: record<benefitClass: string, benefitClassEffectiveDate: string, benefitSalary: float, benefitSalaryEffectiveDate: string, doNotApplyAdministrativePeriod: bool, isMeasureAcaEligibility: bool>, birthDate: string, coEmpCode: string, companyFEIN: string, companyName: string, currency: string, customBooleanFields: table<category: string, label: string, value: bool>, customDateFields: table<category: string, label: string, value: string>, customDropDownFields: table<category: string, label: string, value: string>, customNumberFields: table<category: string, label: string, value: float>, customTextFields: table<category: string, label: string, value: string>, departmentPosition: record<changeReason: string, clockBadgeNumber: string, costCenter1: string, costCenter2: string, costCenter3: string, effectiveDate: string, employeeType: string, equalEmploymentOpportunityClass: string, isMinimumWageExempt: bool, isOvertimeExempt: bool, isSupervisorReviewer: bool, isUnionDuesCollected: bool, isUnionInitiationCollected: bool, jobTitle: string, payGroup: string, positionCode: string, reviewerCompanyNumber: string, reviewerEmployeeId: string, shift: string, supervisorCompanyNumber: string, supervisorEmployeeId: string, tipped: string, unionAffiliationDate: string, unionCode: string, unionPosition: string, workersCompensation: string>, disabilityDescription: string, emergencyContacts: table<address1: string, address2: string, city: string, country: string, county: string, email: string, firstName: string, homePhone: string, lastName: string, mobilePhone: string, notes: string, pager: string, primaryPhone: string, priority: string, relationship: string, state: string, syncEmployeeInfo: bool, workExtension: string, workPhone: string, zip: string>, employeeId: string, ethnicity: string, federalTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, taxCalculationCode: string, w4FormYear: int>, firstName: string, gender: string, homeAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, mobilePhone: string, phone: string, postalCode: string, state: string>, isHighlyCompensated: bool, isSmoker: bool, lastName: string, localTax: table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>, maritalStatus: string, middleName: string, nonPrimaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, reciprocityCode: string, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, ownerPercent: float, preferredName: string, primaryPayRate: record<annualSalary: float, baseRate: float, beginCheckDate: string, changeReason: string, defaultHours: float, effectiveDate: string, isAutoPay: bool, payFrequency: string, payGrade: string, payRateNote: string, payType: string, ratePer: string, salary: float>, primaryStateTax: record<amount: float, deductionsAmount: float, dependentsAmount: float, exemptions: float, exemptions2: float, filingStatus: string, higherRate: bool, otherIncomeAmount: float, percentage: float, specialCheckCalc: string, taxCalculationCode: string, taxCode: string, w4FormYear: int>, priorLastName: string, salutation: string, ssn: string, status: record<adjustedSeniorityDate: string, changeReason: string, effectiveDate: string, employeeStatus: string, hireDate: string, isEligibleForRehire: bool, reHireDate: string, statusType: string, terminationDate: string>, suffix: string, taxSetup: record<fitwExemptNotes: string, fitwExemptReason: string, futaExemptNotes: string, futaExemptReason: string, isEmployee943: bool, isPension: bool, isStatutory: bool, medExemptNotes: string, medExemptReason: string, sitwExemptNotes: string, sitwExemptReason: string, ssExemptNotes: string, ssExemptReason: string, suiExemptNotes: string, suiExemptReason: string, suiState: string, taxDistributionCode1099R: string, taxForm: string>, veteranDescription: string, webTime: record<badgeNumber: string, chargeRate: float, isTimeLaborEnabled: bool>, workAddress: record<address1: string, address2: string, city: string, country: string, county: string, emailAddress: string, location: string, mailStop: string, mobilePhone: string, pager: string, phone: string, phoneExtension: string, postalCode: string, state: string>, workEligibility: record<alienOrAdmissionDocumentNumber: string, attestedDate: string, countryOfIssuance: string, foreignPassportNumber: string, i94AdmissionNumber: string, i9DateVerified: string, i9Notes: string, isI9Verified: bool, isSsnVerified: bool, ssnDateVerified: string, ssnNotes: string, visaType: string, workAuthorization: string, workUntil: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
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
# --departmentPosition shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
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
export def "companies-employees update" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --additional-rate: list # Add Additional Rates. — item shape: {changeReason?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, endCheckDate?: string, job?: string, rate?: float, rateCode?: string, rateNotes?: string, ratePer?: string, shift?: string}
  --benefit-setup: record # Add or update setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --co-emp-code: string # Unique idenifier for SSO.Max length: 20 (nullable)
  --company-fein: string # Company FEIN as defined in Web Pay, applicable with GET requests only. Max length: 20 (nullable)
  --company-name: string # Company name as defined in Web Pay, applicable with GET requests only. Max length: 50 (nullable)
  --currency: string # Employee is paid in this currency. Max length: 30 (nullable)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: record # Add or update home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, reviewerCompanyNumber?: string, reviewerEmployeeId?: string, shift?: string, ... (7 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --emergency-contacts: list # Add or update Emergency Contacts. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, email?: string, firstName: string, homePhone?: string, lastName: string, mobilePhone?: string, notes?: string, pager?: string, primaryPhone?: string, priority?: string, relationship?: string, state?: string, syncEmployeeInfo?: bool, workExtension?: string, workPhone?: string, zip?: string}
  --body-employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID.Max length: 9 (nullable)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: record # Add or update federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: record # Add or update employee's home address, personal phone numbers, and personal email. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-highly-compensated: oneof<nothing, bool> # Indicates if employee meets the highly compensated employee criteria.
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker.
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add, update, or delete local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: record # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — shape: {accountNumber?: string, accountType?: string, blockSpecial?: bool, isSkipPreNote?: bool, nameOnAccount?: string, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: record # Add or update non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --owner-percent: float # Percentage of employee's ownership in the company, entered as a whole number. Decimal (12,2) (nullable)
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: record # Add or update hourly or salary pay rate, effective date, and pay frequency. — shape: {annualSalary?: float, baseRate?: float, beginCheckDate?: string, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payRateNote?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: record # Add or update primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. Sending an updated primary state will replace the current primary state. — shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: record # Add or update employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool, reHireDate?: string, statusType?: string, terminationDate?: string}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --tax-setup: record # Add tax form, 1099 exempt reasons and notes, and 943 agricultural employee information. Once the employee receives wages, this information cannot be updated. Add or update SUI tax state, retirement plan, and statutory information. — shape: {fitwExemptNotes?: string, fitwExemptReason?: string, futaExemptNotes?: string, futaExemptReason?: string, isEmployee943?: bool, isPension?: bool, isStatutory?: bool, medExemptNotes?: string, medExemptReason?: string, sitwExemptNotes?: string, sitwExemptReason?: string, ssExemptNotes?: string, ssExemptReason?: string, suiExemptNotes?: string, suiExemptReason?: string, suiState?: string, taxDistributionCode1099R?: string, taxForm?: string}
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add or update Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: record # Add or update employee's work address, phone numbers, and email. Work Location drop down field is not included. — shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, location?: string, mailStop?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: record # Add or update I-9 work authorization information. — shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}") $auth.query)
  let req_body = {"additionalDirectDeposit": $additional_direct_deposit, "additionalRate": $additional_rate, "benefitSetup": $benefit_setup, "birthDate": $birth_date, "coEmpCode": $co_emp_code, "companyFEIN": $company_fein, "companyName": $company_name, "currency": $currency, "customBooleanFields": $custom_boolean_fields, "customDateFields": $custom_date_fields, "customDropDownFields": $custom_drop_down_fields, "customNumberFields": $custom_number_fields, "customTextFields": $custom_text_fields, "departmentPosition": $department_position, "disabilityDescription": $disability_description, "emergencyContacts": $emergency_contacts, "employeeId": $body_employee_id, "ethnicity": $ethnicity, "federalTax": $federal_tax, "firstName": $first_name, "gender": $gender, "homeAddress": $home_address, "isHighlyCompensated": $is_highly_compensated, "isSmoker": $is_smoker, "lastName": $last_name, "localTax": $local_tax, "mainDirectDeposit": $main_direct_deposit, "maritalStatus": $marital_status, "middleName": $middle_name, "nonPrimaryStateTax": $non_primary_state_tax, "ownerPercent": $owner_percent, "preferredName": $preferred_name, "primaryPayRate": $primary_pay_rate, "primaryStateTax": $primary_state_tax, "priorLastName": $prior_last_name, "salutation": $salutation, "ssn": $ssn, "status": $status, "suffix": $suffix, "taxSetup": $tax_setup, "veteranDescription": $veteran_description, "webTime": $web_time, "workAddress": $work_address, "workEligibility": $work_eligibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "patch"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-patch $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add/update additional rates
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/additionalRates
# operationId: Add or update additional rates
export def "companies-employees-additional-rates create-or-update" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --change-reason: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Change Reason drop down. (nullable)
  --cost-center1: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 1 drop down. This cell must be in a text format. (nullable)
  --cost-center2: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 2 drop down. This cell must be in a text format. (nullable)
  --cost-center3: string # Not required. Valid values must match one of the system coded cost centers available in the Additional Rates Cost Center level 3 drop down. This cell must be in a text format. (nullable)
  --effective-date: string # Required. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --end-check-date: string # Not required. Must match one of the system coded check dates available in the Additional Rates End Check Date drop down. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --job: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Job drop down. (nullable)
  --rate: float # Required. Enter dollar amount that corresponds to the Per selection. (nullable)
  --rate-code: string # Required. If populated, must match one of the system coded values available in the Additional Rates Rate Code drop down. (nullable)
  --rate-notes: string # Not required.Max length: 4000 (nullable)
  --rate-per: string # Required. Valid values are HOUR or WEEK. (nullable)
  --shift: string # Not required. If populated, must match one of the system coded values available in the Additional Rates Shift drop down. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/additionalRates") $auth.query)
  let req_body = {"changeReason": $change_reason, "costCenter1": $cost_center1, "costCenter2": $cost_center2, "costCenter3": $cost_center3, "effectiveDate": $effective_date, "endCheckDate": $end_check_date, "job": $job, "rate": $rate, "rateCode": $rate_code, "rateNotes": $rate_notes, "ratePer": $rate_per, "shift": $shift} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Add/update employee's benefit setup
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/benefitSetup
# operationId: Update or add employee benefit setup
export def "companies-employees-benefit-setup update-or-create" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --benefit-class: string # Benefit Class code. Values are configured in Web Pay Company > Setup > Benefits > Classes.Max length: 30 (nullable)
  --benefit-class-effective-date: string # Date when Benefit Class takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --benefit-salary: float # Salary used to configure benefits.Decimal(12,2) (nullable)
  --benefit-salary-effective-date: string # Date when Benefit Salary takes effect. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --do-not-apply-administrative-period: oneof<nothing, bool> # Applicable only for HR Enhanced clients and Benefit Classes with ACA Employment Type of Full Time. (nullable)
  --is-measure-aca-eligibility: oneof<nothing, bool> # Only valid for HR Enhanced clients and Benefit Classes that are ACA Employment Type of Full Time. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/benefitSetup") $auth.query)
  let req_body = {"benefitClass": $benefit_class, "benefitClassEffectiveDate": $benefit_class_effective_date, "benefitSalary": $benefit_salary, "benefitSalaryEffectiveDate": $benefit_salary_effective_date, "doNotApplyAdministrativePeriod": $do_not_apply_administrative_period, "isMeasureAcaEligibility": $is_measure_aca_eligibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get All Direct Deposit
#
# GET /v2/companies/{companyId}/employees/{employeeId}/directDeposit
# operationId: Get All Direct Deposit
export def "companies-employees-direct-deposit get-list" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<additionalDirectDeposit: list<record>, mainDirectDeposit: record<accountNumber: string, accountType: string, blockSpecial: bool, isSkipPreNote: bool, nameOnAccount: string, preNoteDate: string, routingNumber: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/directDeposit") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get All Earnings
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings
# operationId: Get All Earnings
export def "companies-employees-earnings get-list" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/earnings") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/Update Earning
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/earnings
# operationId: Add or update an employee earning
export def "companies-employees-earnings create-or-update" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --agency: string # Third-party agency associated with earning. Must match Company setup.Max length: 10 (nullable)
  --amount: float # Value that matches CalculationCode to add to gross wages. For percentage (%), enter whole number (10 = 10%). Decimal(12,2) (nullable)
  --annual-maximum: float # Year to Date dollar amount not to be exceeded for an earning in the calendar year. Used only with company driven maximums. Decimal(12,2) (nullable)
  --calculation-code: string # Defines how earnings are calculated. Common values are *% (percentage of gross), flat (flat dollar amount)*. Defaulted to the Company setup calcCode for earning. Max length: 20 (nullable)
  --cost-center1: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --cost-center2: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --cost-center3: string # Cost Center associated with earning. Must match Company setup. Max length: 10 (nullable)
  --earning-code: string # Earning code. Must match Company setup. Max length: 10 (nullable)
  --effective-date: string # Date earning is active. Defaulted to run date or check date based on Company setup. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --end-date: string # Stop date of an earning. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
  --frequency: string # Needed if earning is applied differently from the payroll frequency (one time earning for example). Max length: 5 (nullable)
  --goal: float # Dollar amount. The employee earning will stop when the goal amount is reached. Decimal(12,2) (nullable)
  --hours-or-units: float # The value is used in conjunction with the Rate field. When entering Group Term Life Insurance (GTL), it should contain the full amount of the group term life insurance policy. Decimal(12,2) (nullable)
  --is-self-insured: oneof<nothing, bool> # Used for ACA. If not entered, defaulted to Company earning setup. (nullable)
  --job-code: string # Job code associated with earnings. Must match Company setup. Max length: 20 (nullable)
  --miscellaneous-info: string # Information to print on the check stub if agency is set up for this earning. Max length: 50 (nullable)
  --paid-towards-goal: float # Amount already paid to employee toward goal. Decimal(12,2) (nullable)
  --pay-period-maximum: float # Maximum amount of the earning on a single paycheck. Decimal(12,2) (nullable)
  --pay-period-minimum: float # Minimum amount of the earning on a single paycheck. Decimal(12,2) (nullable)
  --rate: float # Rate is used in conjunction with the hoursOrUnits field. Decimal(12,2) (nullable)
  --rate-code: string # Rate Code applies to additional pay rates entered for an employee. Must match Company setup. Max length: 10 (nullable)
  --start-date: string # Start date of an earning based on payroll calendar. Common formats are MM-DD-CCYY, CCYY-MM-DD. (nullable, format: paylocity-date)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/earnings") $auth.query)
  let req_body = {"agency": $agency, "amount": $amount, "annualMaximum": $annual_maximum, "calculationCode": $calculation_code, "costCenter1": $cost_center1, "costCenter2": $cost_center2, "costCenter3": $cost_center3, "earningCode": $earning_code, "effectiveDate": $effective_date, "endDate": $end_date, "frequency": $frequency, "goal": $goal, "hoursOrUnits": $hours_or_units, "isSelfInsured": $is_self_insured, "jobCode": $job_code, "miscellaneousInfo": $miscellaneous_info, "paidTowardsGoal": $paid_towards_goal, "payPeriodMaximum": $pay_period_maximum, "payPeriodMinimum": $pay_period_minimum, "rate": $rate, "rateCode": $rate_code, "startDate": $start_date} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Earnings by Earning Code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}
# operationId: Get Earnings by Earning Code
export def "companies-employees-earnings get-by-code" [
  company_id: string
  employee_id: string
  earning_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($earning_code | is-empty) { error make --unspanned { msg: "path parameter 'earningCode' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), earning_code: (encode-path-segment $earning_code)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/earnings/{earning_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Delete Earning by Earning Code and Start Date
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# operationId: Delete Earning by Earning Code and Start Date
export def "companies-employees-earnings delete-by-code-and-start-date" [
  company_id: string
  employee_id: string
  earning_code: string
  start_date: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($earning_code | is-empty) { error make --unspanned { msg: "path parameter 'earningCode' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'startDate' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), earning_code: (encode-path-segment $earning_code), start_date: (encode-path-segment $start_date)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/earnings/{earning_code}/{start_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get Earning by Earning Code and Start Date
#
# GET /v2/companies/{companyId}/employees/{employeeId}/earnings/{earningCode}/{startDate}
# operationId: Get Earning by Earning Code and Start Date
export def "companies-employees-earnings get-by-code-and-start-date" [
  company_id: string
  employee_id: string
  earning_code: string
  start_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<agency: string, amount: float, annualMaximum: float, calculationCode: string, costCenter1: string, costCenter2: string, costCenter3: string, earningCode: string, effectiveDate: string, endDate: string, frequency: string, goal: float, hoursOrUnits: float, isSelfInsured: bool, jobCode: string, miscellaneousInfo: string, paidTowardsGoal: float, payPeriodMaximum: float, payPeriodMinimum: float, rate: float, rateCode: string, startDate: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($earning_code | is-empty) { error make --unspanned { msg: "path parameter 'earningCode' must be non-empty" } }
  if ($start_date | is-empty) { error make --unspanned { msg: "path parameter 'startDate' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), earning_code: (encode-path-segment $earning_code), start_date: (encode-path-segment $start_date)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/earnings/{earning_code}/{start_date}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update emergency contacts
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/emergencyContacts
# operationId: Add or update emergency contacts
export def "companies-employees-emergency-contacts create-or-update" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --address1: string # 1st address line. (nullable)
  --address2: string # 2nd address line. (nullable)
  --city: string # City. (nullable)
  --country: string # County. (nullable)
  --county: string # Country. Must be a valid 3 character country code. Common values are *USA* (United States), *CAN* (Canada). (nullable)
  --email: string # Contact email. Must be valid email address format. (nullable)
  --first-name: string # Required. Contact first name. Max length: 40 (nullable)
  --home-phone: string # Contact Home Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --last-name: string # Required. Contact last name. Max length: 40 (nullable)
  --mobile-phone: string # Contact Mobile Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --notes: string # Notes. Max length: 1000 (nullable)
  --pager: string # Contact Pager. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --primary-phone: string # Required. Contact primary phone type. Must match Company setup. Valid values are H (Home), M (Mobile), P (Pager), W (Work) (nullable)
  --priority: string # Required. Contact priority. Valid values are *P* (Primary) or *S* (Secondary). (nullable)
  --relationship: string # Required. Contact relationship. Must match Company setup. Common values are Spouse, Mother, Father. (nullable)
  --state: string # State or Province. If U.S. address, must be valid 2 character state code. Common values are *IL* (Illinois), *CA* (California). (nullable)
  --sync-employee-info: oneof<nothing, bool> # Valid values are *true* or *false*.
  --work-extension: string # Work Extension. (nullable)
  --work-phone: string # Contact Work Phone. Valid phone format *(###) #######* or *######-####* or *### ### ####* or *##########* or, if international, starts with *+#*, only spaces and digits allowed. (nullable)
  --zip: string # Postal code. If U.S. address, must be a valid zip code. (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/emergencyContacts") $auth.query)
  let req_body = {"address1": $address1, "address2": $address2, "city": $city, "country": $country, "county": $county, "email": $email, "firstName": $first_name, "homePhone": $home_phone, "lastName": $last_name, "mobilePhone": $mobile_phone, "notes": $notes, "pager": $pager, "primaryPhone": $primary_phone, "priority": $priority, "relationship": $relationship, "state": $state, "syncEmployeeInfo": $sync_employee_info, "workExtension": $work_extension, "workPhone": $work_phone, "zip": $zip} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get all local taxes
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# operationId: Get all local taxes
export def "companies-employees-local-taxes get-list" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/localTaxes") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add new local tax
#
# POST /v2/companies/{companyId}/employees/{employeeId}/localTaxes
# operationId: Add local tax
export def "companies-employees-local-taxes create-tax" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --exemptions: float # Local tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # Local tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee local tax filing status. Must match specific local tax setup. Max length: 50 (nullable)
  --resident-psd: string # Resident PSD (political subdivision code) applicable in PA. Must match Company setup. Max length: 9 (nullable)
  --tax-code: string # Local tax code.Max length: 50 (nullable)
  --work-psd: string # Work location PSD. Must match Company setup. Max length: 9 (nullable)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/localTaxes") $auth.query)
  let req_body = {"exemptions": $exemptions, "exemptions2": $exemptions2, "filingStatus": $filing_status, "residentPSD": $resident_psd, "taxCode": $tax_code, "workPSD": $work_psd} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}

# Delete local tax by tax code
#
# DELETE /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# operationId: Delete local tax by tax code
export def "companies-employees-local-taxes delete-tax-by-tax-code" [
  company_id: string
  employee_id: string
  tax_code: string
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
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($tax_code | is-empty) { error make --unspanned { msg: "path parameter 'taxCode' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), tax_code: (encode-path-segment $tax_code)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/localTaxes/{tax_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "delete"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-delete $req null $insecure $raw $allow_errors $full [204]
}

# Get local taxes by tax code
#
# GET /v2/companies/{companyId}/employees/{employeeId}/localTaxes/{taxCode}
# operationId: Get local tax by tax code
export def "companies-employees-local-taxes get-tax-by-tax-code" [
  company_id: string
  employee_id: string
  tax_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<exemptions: float, exemptions2: float, filingStatus: string, residentPSD: string, taxCode: string, workPSD: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($tax_code | is-empty) { error make --unspanned { msg: "path parameter 'taxCode' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), tax_code: (encode-path-segment $tax_code)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/localTaxes/{tax_code}") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update non-primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/nonprimaryStateTax
# operationId: Add or update non-primary state tax
export def "companies-employees-nonprimary-state-tax create-or-update-non-primary" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code. Max length: 50 (nullable)
  --deductions-amount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. Decimal (12,2)
  --dependents-amount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. Decimal (12,2)
  --exemptions: float # State tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).Max length: 50 (nullable)
  --higher-rate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. Boolean
  --other-income-amount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. Decimal (12,2)
  --percentage: float # State Tax percentage. Decimal (12,2) (nullable)
  --reciprocity-code: string # Non-primary state tax reciprocity code. Max length: 50 (nullable)
  --special-check-calc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). Max length: 10 (nullable)
  --tax-calculation-code: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). Max length: 10 (nullable)
  --tax-code: string # State tax code. Max length: 50 (nullable)
  --w4-form-year: int # The state W4 form year Integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/nonprimaryStateTax") $auth.query)
  let req_body = {"amount": $amount, "deductionsAmount": $deductions_amount, "dependentsAmount": $dependents_amount, "exemptions": $exemptions, "exemptions2": $exemptions2, "filingStatus": $filing_status, "higherRate": $higher_rate, "otherIncomeAmount": $other_income_amount, "percentage": $percentage, "reciprocityCode": $reciprocity_code, "specialCheckCalc": $special_check_calc, "taxCalculationCode": $tax_calculation_code, "taxCode": $tax_code, "w4FormYear": $w4_form_year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get employee pay statement details data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}
# operationId: Gets employee pay statement detail data based on the specified year
export def "companies-employees-paystatement-details get-gets-pay-statement-data-based-on-specified" [
  company_id: string
  employee_id: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), year: (encode-path-segment $year)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/paystatement/details/{year}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenumber": $pagenumber, "includetotalcount": $includetotalcount, "codegroup": $codegroup} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get employee pay statement details data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/details/{year}/{checkDate}
# operationId: Gets employee pay statement detail data based on the specified year and check date
export def "companies-employees-paystatement-details check-gets-pay-statement-data-based-on-specified-and-date" [
  company_id: string
  employee_id: string
  year: string
  check_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<amount: float, checkDate: string, det: string, detCode: string, detType: string, eligibleCompensation: float, hours: float, rate: float, transactionNumber: int, transactionType: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($check_date | is-empty) { error make --unspanned { msg: "path parameter 'checkDate' must be non-empty" } }
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), year: (encode-path-segment $year), check_date: (encode-path-segment $check_date)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/paystatement/details/{year}/{check_date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenumber": $pagenumber, "includetotalcount": $includetotalcount, "codegroup": $codegroup} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get employee pay statement summary data for the specified year.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}
# operationId: Gets employee pay statement summary data based on the specified year
export def "companies-employees-paystatement-summary get-gets-pay-statement-data-based-on-specified" [
  company_id: string
  employee_id: string
  year: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), year: (encode-path-segment $year)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/paystatement/summary/{year}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenumber": $pagenumber, "includetotalcount": $includetotalcount, "codegroup": $codegroup} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Get employee pay statement summary data for the specified year and check date.
#
# GET /v2/companies/{companyId}/employees/{employeeId}/paystatement/summary/{year}/{checkDate}
# operationId: Gets employee pay statement summary data based on the specified year and check date
export def "companies-employees-paystatement-summary check-gets-pay-statement-data-based-on-specified-and-date" [
  company_id: string
  employee_id: string
  year: string
  check_date: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --pagesize: int # Number of records per page. Default value is 25.
  --pagenumber: int # Page number to retrieve; page numbers are 0-based (so to get the first page of results, pass pagenumber=0). Default value is 0.
  --includetotalcount: oneof<nothing, bool> # Whether to include the total record count in the header's X-Pcty-Total-Count property. Default value is true.
  --codegroup: string # Retrieve pay statement details related to specific deduction, earning or tax types. Common values include 401k, Memo, Reg, OT, Cash Tips, FED and SITW.
]: nothing -> table<autoPay: bool, beginDate: string, checkDate: string, checkNumber: int, directDepositAmount: float, endDate: string, grossPay: float, hours: float, netCheck: float, netPay: float, overtimeDollars: float, overtimeHours: float, process: int, regularDollars: float, regularHours: float, transactionNumber: int, voucherNumber: int, workersCompCode: string, year: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  if ($year | is-empty) { error make --unspanned { msg: "path parameter 'year' must be non-empty" } }
  if ($check_date | is-empty) { error make --unspanned { msg: "path parameter 'checkDate' must be non-empty" } }
  let qp = [(serialize-qp "pagesize" $pagesize "scalar") (serialize-qp "pagenumber" $pagenumber "scalar") (serialize-qp "includetotalcount" $includetotalcount "scalar") (serialize-qp "codegroup" $codegroup "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id), year: (encode-path-segment $year), check_date: (encode-path-segment $check_date)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/paystatement/summary/{year}/{check_date}") $qp $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: ({"pagesize": $pagesize, "pagenumber": $pagenumber, "includetotalcount": $includetotalcount, "codegroup": $codegroup} | compact)
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update primary state tax
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/primaryStateTax
# operationId: Add or update primary state tax
export def "companies-employees-primary-state-tax create-or-update" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --amount: float # State tax code. Max length: 50 (nullable)
  --deductions-amount: float # Box 4(b) on form W4 (year 2020 or later): Deductions amount. Decimal (12,2)
  --dependents-amount: float # Box 3 on form W4 (year 2020 or later): Total dependents amount. Decimal (12,2)
  --exemptions: float # State tax exemptions value.Decimal (12,2) (nullable)
  --exemptions2: float # State tax exemptions 2 value.Decimal (12,2) (nullable)
  --filing-status: string # Employee state tax filing status. Common values are *S* (Single), *M* (Married).Max length: 50 (nullable)
  --higher-rate: oneof<nothing, bool> # Box 2(c) on form W4 (year 2020 or later): Multiple Jobs or Spouse Works. Boolean
  --other-income-amount: float # Box 4(a) on form W4 (year 2020 or later): Other income amount. Decimal (12,2)
  --percentage: float # State Tax percentage. Decimal (12,2) (nullable)
  --special-check-calc: string # Supplemental check calculation code. Common values are *Blocked* (Taxes blocked on Supplemental checks), *Supp* (Use supplemental Tax Rate-Code). Max length: 10 (nullable)
  --tax-calculation-code: string # Tax calculation code. Common values are *F* (Flat), *P* (Percentage), *FDFP* (Flat Dollar Amount plus Fixed Percentage). Max length: 10 (nullable)
  --tax-code: string # State tax code. Max length: 50 (nullable)
  --w4-form-year: int # The state W4 form year Integer
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/primaryStateTax") $auth.query)
  let req_body = {"amount": $amount, "deductionsAmount": $deductions_amount, "dependentsAmount": $dependents_amount, "exemptions": $exemptions, "exemptions2": $exemptions2, "filingStatus": $filing_status, "higherRate": $higher_rate, "otherIncomeAmount": $other_income_amount, "percentage": $percentage, "specialCheckCalc": $special_check_calc, "taxCalculationCode": $tax_calculation_code, "taxCode": $tax_code, "w4FormYear": $w4_form_year} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get sensitive data
#
# GET /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# operationId: Get sensitive data
export def "companies-employees-sensitivedata get-sensitive-data" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> table<disability: record<disability: string, disabilityClassifications: list, hasDisability: string>, ethnicity: record<ethnicRacialIdentities: list, ethnicity: string>, gender: record<displayPronouns: bool, genderIdentityDescription: string, identifyAsLegalGender: string, legalGender: string, pronouns: string, sexualOrientation: string>, veteran: record<isVeteran: string, veteran: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/sensitivedata") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Add/update sensitive data
#
# PUT /v2/companies/{companyId}/employees/{employeeId}/sensitivedata
# operationId: Add or update Sensitive Data
# --disability shape: {disability?: string, disabilityClassifications?: list, hasDisability?: string}
# --ethnicity shape: {ethnicRacialIdentities?: list, ethnicity?: string}
# --gender shape: {displayPronouns?: bool, genderIdentityDescription?: string, identifyAsLegalGender?: string, legalGender?: string, pronouns?: string, sexualOrientation?: string}
# --veteran shape: {isVeteran?: string, veteran?: string}
export def "companies-employees-sensitivedata create-or-update-sensitive-data" [
  company_id: string
  employee_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --disability: record # Add or update disability data. — shape: {disability?: string, disabilityClassifications?: list, hasDisability?: string}
  --ethnicity: record # Add or update ethnicity data. — shape: {ethnicRacialIdentities?: list, ethnicity?: string}
  --gender: record # Add or update gender data. — shape: {displayPronouns?: bool, genderIdentityDescription?: string, identifyAsLegalGender?: string, legalGender?: string, pronouns?: string, sexualOrientation?: string}
  --veteran: record # Add or update veteran data. — shape: {isVeteran?: string, veteran?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  if ($employee_id | is-empty) { error make --unspanned { msg: "path parameter 'employeeId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id), employee_id: (encode-path-segment $employee_id)} | format pattern "/v2/companies/{company_id}/employees/{employee_id}/sensitivedata") $auth.query)
  let req_body = {"disability": $disability, "ethnicity": $ethnicity, "gender": $gender, "veteran": $veteran} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "put"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-put $req $req_body $insecure $raw $allow_errors $full [200]
}

# Get Company-Specific Open API Documentation
#
# GET /v2/companies/{companyId}/openapi
# operationId: Get company-specific Open API documentation
export def "companies-openapi get-company-specific-open-documentation" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --authorization: string # Bearer + JWT
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v2/companies/{company_id}/openapi") $auth.query)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"Authorization": $authorization} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let req = {
    method: "get"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: null
    content_type: null
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-get $req $insecure $raw $allow_errors $full [200]
}

# Obtain new client secret.
#
# POST /v2/credentials/secrets
# operationId: Add Client Secret
export def "credentials-secrets create-client" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  code: string # A value sent with the 'ACTION NEEDED: Web Link API Credentials Expiring Soon.' email notification.
]: any -> table<clientSecret: string, clientSecretExpirationDate: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/v2/credentials/secrets" $auth.query)
  let req_body = {"code": $code} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [200]
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
# --departmentPosition item shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, ... (5 more fields)}
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
export def "weblinkstaging-companies-employees-newemployees create-new-to-web-link" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --additional-direct-deposit: list # Add up to 19 direct deposit accounts in addition to the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with information provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, amount?: float, amountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --benefit-setup: list # Add setup values used for employee benefits integration, insurance plan settings, and ACA reporting. — item shape: {benefitClass?: string, benefitClassEffectiveDate?: string, benefitSalary?: float, benefitSalaryEffectiveDate?: string, doNotApplyAdministrativePeriod?: bool, isMeasureAcaEligibility?: bool}
  --birth-date: string # Employee birthdate. Common formats include *MM-DD-CCYY*, *CCYY-MM-DD*. (nullable, format: paylocity-date)
  --custom-boolean-fields: list # Up to 8 custom fields of boolean (checkbox) type value. — item shape: {category: "PayrollAndHR", label: string, value: bool}
  --custom-date-fields: list # Up to 8 custom fields of the date type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-drop-down-fields: list # Up to 8 custom fields of the dropdown type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --custom-number-fields: list # Up to 8 custom fields of numeric type value. — item shape: {category: "PayrollAndHR", label: string, value: float}
  --custom-text-fields: list # Up to 8 custom fields of text type value. — item shape: {category: "PayrollAndHR", label: string, value: string}
  --department-position: list # Add home department cost center, position, supervisor, reviewer, employment type, EEO class, pay settings, and union information. — item shape: {changeReason?: string, clockBadgeNumber?: string, costCenter1?: string, costCenter2?: string, costCenter3?: string, effectiveDate?: string, employeeType?: string, equalEmploymentOpportunityClass?: string, isMinimumWageExempt?: bool, isOvertimeExempt?: bool, isSupervisorReviewer?: bool, isUnionDuesCollected?: bool, isUnionInitiationCollected?: bool, jobTitle?: string, payGroup?: string, positionCode?: string, shift?: string, supervisorCompanyNumber?: string, supervisorEmployeeId?: string, ... (5 more fields)}
  --disability-description: string # Indicates if employee has disability status. (nullable)
  --employee-id: string # Leave blank to have Web Pay automatically assign the next available employee ID. Max length: 10 (nullable)
  --ethnicity: string # Employee ethnicity. Max length: 10 (nullable)
  --federal-tax: list # Add federal tax amount type (taxCalculationCode), amount or percentage, filing status, and exemptions. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, taxCalculationCode?: string, w4FormYear?: int}
  --first-name: string # Employee first name. Max length: 40 (nullable)
  --fitw-exempt-reason: string # Reason code for FITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --futa-exempt-reason: string # Reason code for FUTA exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor). Max length: 30 (nullable)
  --gender: string # Employee gender. Common values *M* (Male), *F* (Female). Max length: 1 (nullable)
  --home-address: list # Add employee's home address, personal phone numbers, and personal email. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, phone?: string, postalCode?: string, state?: string}
  --is-employee943: oneof<nothing, bool> # Indicates if employee in agriculture or farming. (nullable)
  --is-smoker: oneof<nothing, bool> # Indicates if employee is a smoker. (nullable)
  --last-name: string # Employee last name. Max length: 40 (nullable)
  --local-tax: list # Add local tax code, filing status, and exemptions including PA-PSD taxes. — item shape: {exemptions?: float, exemptions2?: float, filingStatus?: string, residentPSD?: string, taxCode?: string, workPSD?: string}
  --main-direct-deposit: list # Add the main direct deposit account. After deposits are made to any additional direct deposit accounts, the remaining net check is deposited in the main direct deposit account. IMPORTANT: A direct deposit update will remove ALL existing main and additional direct deposit information in WebPay and replace with what is provided on the request. GET API will not return direct deposit data. — item shape: {accountNumber?: string, accountType?: string, isSkipPreNote?: bool, preNoteDate?: string, routingNumber?: string}
  --marital-status: string # Employee marital status. Common values *D (Divorced), M (Married), S (Single), W (Widowed)*. Max length: 10 (nullable)
  --med-exempt-reason: string # Reason code for Medicare exemption. Common values are *501* (5019c)(3) Organization), *IC* (Independent Contractor). Max length: 30 (nullable)
  --middle-name: string # Employee middle name. Max length: 20 (nullable)
  --non-primary-state-tax: list # Add non-primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, supplemental check (specialCheckCalc), and reciprocity code information. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, reciprocityCode?: string, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --preferred-name: string # Employee preferred display name. Max length: 20 (nullable)
  --primary-pay-rate: list # Add hourly or salary pay rate, effective date, and pay frequency. — item shape: {baseRate?: float, changeReason?: string, defaultHours?: float, effectiveDate?: string, isAutoPay?: bool, payFrequency?: string, payGrade?: string, payType?: string, ratePer?: string, salary?: float}
  --primary-state-tax: list # Add primary state tax code, amount type (taxCalculationCode), amount or percentage, filing status, exemptions, and supplemental check (specialCheckCalc) information. Only one primary state is allowed. — item shape: {amount?: float, deductionsAmount?: float, dependentsAmount?: float, exemptions?: float, exemptions2?: float, filingStatus?: string, higherRate?: bool, otherIncomeAmount?: float, percentage?: float, specialCheckCalc?: string, taxCalculationCode?: string, taxCode?: string, w4FormYear?: int}
  --prior-last-name: string # Prior last name if applicable.Max length: 40 (nullable)
  --salutation: string # Employee preferred salutation. Max length: 10 (nullable)
  --sitw-exempt-reason: string # Reason code for SITW exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --ss-exempt-reason: string # Reason code for Social Security exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --ssn: string # Employee social security number. Leave it blank if valid social security number not available. Max length: 11 (nullable)
  --status: list # Add employee status, change reason, effective date, and adjusted seniority date. Note that companies that are still in Implementation cannot hire future employees. — item shape: {adjustedSeniorityDate?: string, changeReason?: string, effectiveDate?: string, employeeStatus?: string, hireDate?: string, isEligibleForRehire?: bool}
  --suffix: string # Employee name suffix. Common values are *Jr, Sr, II*.Max length: 30 (nullable)
  --sui-exempt-reason: string # Reason code for SUI exemption. Common values are *SE* (Statutory employee), *CR* (clergy/Religious). Max length: 30 (nullable)
  --sui-state: string # Employee SUI (State Unemployment Insurance) state. Max length: 2 (nullable)
  --tax-distribution-code1099-r: string # Employee 1099R distribution code. Common values are *7* (Normal Distribution), *F* (Charitable Gift Annuity). Max length: 1 (nullable)
  --tax-form: string # Employee tax form for reporting income. Valid values are *W2, 1099M, 1099R*. Default is W2. Max length: 15 (nullable)
  --veteran-description: string # Indicates if employee is a veteran. (nullable)
  --web-time: record # Add Web Time badge number and charge rate and synchronize Web Pay and Web Time employee data. — shape: {badgeNumber?: string, chargeRate?: float, isTimeLaborEnabled?: bool}
  --work-address: list # Add employee's work address, phone numbers, and email. Work Location drop down field is not included. — item shape: {address1?: string, address2?: string, city?: string, country?: string, county?: string, emailAddress?: string, mobilePhone?: string, pager?: string, phone?: string, phoneExtension?: string, postalCode?: string, state?: string}
  --work-eligibility: list # Add I-9 work authorization information. — item shape: {alienOrAdmissionDocumentNumber?: string, attestedDate?: string, countryOfIssuance?: string, foreignPassportNumber?: string, i94AdmissionNumber?: string, i9DateVerified?: string, i9Notes?: string, isI9Verified?: bool, isSsnVerified?: bool, ssnDateVerified?: string, ssnNotes?: string, visaType?: string, workAuthorization?: string, workUntil?: string}
]: any -> table<trackingNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/v2/weblinkstaging/companies/{company_id}/employees/newemployees") $auth.query)
  let req_body = {"additionalDirectDeposit": $additional_direct_deposit, "benefitSetup": $benefit_setup, "birthDate": $birth_date, "customBooleanFields": $custom_boolean_fields, "customDateFields": $custom_date_fields, "customDropDownFields": $custom_drop_down_fields, "customNumberFields": $custom_number_fields, "customTextFields": $custom_text_fields, "departmentPosition": $department_position, "disabilityDescription": $disability_description, "employeeId": $employee_id, "ethnicity": $ethnicity, "federalTax": $federal_tax, "firstName": $first_name, "fitwExemptReason": $fitw_exempt_reason, "futaExemptReason": $futa_exempt_reason, "gender": $gender, "homeAddress": $home_address, "isEmployee943": $is_employee943, "isSmoker": $is_smoker, "lastName": $last_name, "localTax": $local_tax, "mainDirectDeposit": $main_direct_deposit, "maritalStatus": $marital_status, "medExemptReason": $med_exempt_reason, "middleName": $middle_name, "nonPrimaryStateTax": $non_primary_state_tax, "preferredName": $preferred_name, "primaryPayRate": $primary_pay_rate, "primaryStateTax": $primary_state_tax, "priorLastName": $prior_last_name, "salutation": $salutation, "sitwExemptReason": $sitw_exempt_reason, "ssExemptReason": $ss_exempt_reason, "ssn": $ssn, "status": $status, "suffix": $suffix, "suiExemptReason": $sui_exempt_reason, "suiState": $sui_state, "taxDistributionCode1099R": $tax_distribution_code1099_r, "taxForm": $tax_form, "veteranDescription": $veteran_description, "webTime": $web_time, "workAddress": $work_address, "workEligibility": $work_eligibility} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let req = {
    method: "post"
    url: $full_url
    query: {}
    headers: $auth.headers
    body: $req_body
    content_type: "application/json"
    timeout: ($max_time | default 30min)
    auth: {scheme: $auth.scheme, location: $auth.location}
  }
  if $dry_run { return ({dry_run: true} | merge $req) }
  send-post $req $req_body $insecure $raw $allow_errors $full [201]
}
