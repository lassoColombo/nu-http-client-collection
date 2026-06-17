# Auto-generated client for Credas API vv1
# Source: https://api.apis.guru/v2/specs/credas.co.uk/pi/v1/openapi.json
# Auth: --token flag or $env.CREDAS_API_TOKEN

const BASE_URL = "http://localhost"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CREDAS_API_TOKEN | default "" }
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

def base-url-completer [] { ["http://localhost"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def accept-completer [] { ["application/json" "application/xml" "text/json" "text/xml"] }
def check-type-completer [] { ["0" "1" "2" "3"] }
def document-type-completer [] { ["0" "1" "10" "11" "2" "3" "4" "5" "6" "7" "9"] }
def delivery-method-completer [] { ["0" "1" "2"] }
def check-type-completer-1 [] { ["0" "1" "2" "3" "4" "5" "6" "7" "8"] }
def status-completer [] { ["0" "1" "2" "3"] }
def name-match-routine-completer [] { ["1" "2"] }
def status-completer-1 [] { ["0" "1" "2" "3" "4" "6"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "bank-accounts-verify verify" } } | get name | first)
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

# Verifies bank account details.
#
# POST /api/bank-accounts/verify
# operationId: Verify
# --accountDetails shape: {accountNumber: string, sortcode: string}
# --address shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {forename: string, middleName?: string, surname: string}
export def "bank-accounts-verify verify" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  account_details: record # shape: {accountNumber: string, sortcode: string}
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> record<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/bank-accounts/verify")
  let body = {"accountDetails": $account_details, "address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Searches for a company based on its Company Number and returns its details.
#
# POST /api/companies
# operationId: SearchCompany
export def "companies list-company" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --company-number: string # The company registration number of the company that should be searched.
  --apikey: string # ApiKey supplied.
]: nothing -> record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "companyNumber" $company_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/companies" $qp)
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GET /api/companies/{companyId}
#
# operationId: GetCompany
export def "companies get-company" [
  company_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({company_id: $company_id} | format pattern "/api/companies/{company_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check includes identifying bankruptcy, insolvency, CCJ's or Company Directorship.
#
# POST /api/credit-status/perform
# operationId: CheckCreditStatus
# --address shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
export def "credit-status-perform check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: table<address1: string, address2: string, address3: string, address4: string, address5: string, amount: string, caseNumber: string, courtName: string, dateEnd: string, dob: string, judgementDate: string, judgementType: int, judgementTypeText: string, name: string, postcode: string>, checkDate: string, companyDirector: table<companyAppointments: list, companyName: string, companyRegNo: string, dateAppointed: string, matchType: int, matchTypeText: string, registeredOffice: string>, hasBeenOverridden: bool, insolvency: table<address: record, aliases: string, assetTotal: string, caseNo: string, caseType: string, court: string, debtTotal: string, description: string, dob: string, name: string, occupation: string, presentationDate: string, previousAddress: record, serviceOffice: string, startDate: string, status: string, telephoneNumber: string, tradingNames: string, type: int, typeText: string>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/credit-status/perform")
  let body = {"address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates new data check against a specified registration.
#
# POST /api/datachecks
# operationId: AddDataCheck
# --currentAddress shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
export def "datachecks create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  check_type: int@check-type-completer # The value of checkType dictates what checks are performed. <br/>The StandardAml check (value = 1) will check DOB & Mortality. <br/>The InternationalPepSanctions check (value = 3) will check just International PEP & Sanctions. <br/>The EnhancedAml check (value = 2) will perform both these checks and is equivalent to making two calls with values of 1 then 3 and will be charged accordingly. <br />  values=> None = 0, StandardAml = 1, EnhancedAml = 2, InternationalPepSanctions = 3 (format: int32)
  current_address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> record<id: string, regCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/datachecks")
  let body = {"checkType": $check_type, "currentAddress": $current_address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Add an id document image to the specified registration.
#
# POST /api/images/id-document
# operationId: AddIdDocumentImage
# --documentParameters item shape: {key?: string, value?: string}
export def "images-id-document create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  --document-parameters: list # item shape: {key?: string, value?: string}
  document_type: int@document-type-completer # Other = 0, Passport = 1, DrivingLicence = 2, Visa = 3, CscsCard = 4, HomeOfficeLetter = 5, BirthCertificate = 6, NationalIdCard = 7, ResidencePermit = 9, UtilityBill = 11 (format: int32)
  image_data: string
  registration_id: string # format: uuid
]: any -> record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/images/id-document")
  let body = {"documentParameters": $document_parameters, "documentType": $document_type, "imageData": $image_data, "registrationId": $registration_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all id document images associated with a registration.
#
# GET /api/images/id-document/{registrationId}
# operationId: GetIdDocumentImages
export def "images-id-document get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, hiResUrl: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcFacialUrl: string, nfcReadStatus: int, primaryScanId: string, status: int, surname: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registration_id: $registration_id} | format pattern "/api/images/id-document/{registration_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a liveness image (UAP) to the specified registration.
#
# POST /api/images/liveness
# operationId: AddLivenessImage
export def "images-liveness create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  image_data: string
  registration_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/images/liveness")
  let body = {"imageData": $image_data, "registrationId": $registration_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the liveness performed image associated with a registration.
#
# GET /api/images/liveness-performed/{registrationId}
# operationId: GetLivenessPerformedImage
export def "images-liveness-performed get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<base64Data: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registration_id: $registration_id} | format pattern "/api/images/liveness-performed/{registration_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve the liveness action image (UAP) associated with a registration.
#
# GET /api/images/liveness/{registrationId}
# operationId: GetLivenessImage
export def "images-liveness get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<description: string, id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registration_id: $registration_id} | format pattern "/api/images/liveness/{registration_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a detailed report on the analysis that has taken place of a scanned document
#
# GET /api/images/scan-report-pdf/{scanId}
# operationId: GetScanReportPdf
export def "images-scan-report-pdf get" [
  scan_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({scan_id: $scan_id} | format pattern "/api/images/scan-report-pdf/{scan_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Add a selfie image to the registration.
#
# POST /api/images/selfie
# operationId: AddSelfieImage
export def "images-selfie create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  image_data: string
  registration_id: string # format: uuid
]: any -> record<livenessConfirmed: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/images/selfie")
  let body = {"imageData": $image_data, "registrationId": $registration_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve the selfie image associated with a registration.
#
# GET /api/images/selfie/{registrationId}
# operationId: GetSelfieImage
export def "images-selfie get" [
  registration_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<base64Data: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({registration_id: $registration_id} | format pattern "/api/images/selfie/{registration_id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new property registry check against the registration.
#
# POST /api/property-register
# operationId: AddPropertyRegisterCheck
# --address shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {forename: string, middleName?: string, surname: string}
export def "property-register create-property-register-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/property-register")
  let body = {"address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves property registry check associated with the registration.
#
# GET /api/property-register/{id}
# operationId: GetPropertyRegisterCheckResult
export def "property-register get-property-register-check-result" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/property-register/{id}"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets all available RegTypes.
#
# GET /api/reg-types
# operationId: GetAll
export def "reg-types get-all" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/reg-types")
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates new registration.
#
# POST /api/registrations
# operationId: AddRegistration
# --parameters item shape: {key?: string, value?: string}
# --returnUrls shape: {returnUrl?: string}
# --settings shape: {capturePersonalDetails?: bool, nameMatchRoutine?: "1"|"2", requiredChecks?: list, skipEmailStep?: bool}
export def "registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  --dialling-code: string
  --duplicate-acknowledgement: oneof<nothing, bool>
  --email-address: string
  forename: string
  --middle-name: string
  --parameters: list # item shape: {key?: string, value?: string}
  --phone-number: string
  --provide-web-journey-link: oneof<nothing, bool>
  --reference-id: string
  reg_type_id: string # format: uuid
  --return-urls: record # shape: {returnUrl?: string}
  --send-email: oneof<nothing, bool>
  --send-sms: oneof<nothing, bool>
  --settings: record # shape: {capturePersonalDetails?: bool, nameMatchRoutine?: "1"|"2", requiredChecks?: list, skipEmailStep?: bool}
  --significant-person-id: string # format: uuid
  surname: string
]: any -> record<id: string, regCode: string, webJourneyUrl: record<url: string, validUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/registrations")
  let body = {"diallingCode": $dialling_code, "duplicateAcknowledgement": $duplicate_acknowledgement, "emailAddress": $email_address, "forename": $forename, "middleName": $middle_name, "parameters": $parameters, "phoneNumber": $phone_number, "provideWebJourneyLink": $provide_web_journey_link, "referenceId": $reference_id, "regTypeId": $reg_type_id, "returnUrls": $return_urls, "sendEmail": $send_email, "sendSms": $send_sms, "settings": $settings, "significantPersonId": $significant_person_id, "surname": $surname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates new registration record, adds an ID document and optional selfie image in one go.
#
# POST /api/registrations/instant
# operationId: AddInstantRegistration
# --documentParameters item shape: {key?: string, value?: string}
# --parameters item shape: {key?: string, value?: string}
export def "registrations-instant create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  document: string
  --document-parameters: list # item shape: {key?: string, value?: string}
  document_type: int@document-type-completer # Other = 0, Passport = 1, DrivingLicence = 2, Visa = 3, CscsCard = 4, HomeOfficeLetter = 5, BirthCertificate = 6, NationalIdCard = 7, ResidencePermit = 9, UtilityBill = 11 (format: int32)
  forename: string
  --middle-name: string
  --parameters: list # item shape: {key?: string, value?: string}
  --reference-id: string
  reg_type_id: string # format: uuid
  --selfie: string
  --significant-person-id: string # format: uuid
  surname: string
]: any -> record<documentStatus: int, documentType: int, facialMatch: bool, id: string, regCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/registrations/instant")
  let body = {"document": $document, "documentParameters": $document_parameters, "documentType": $document_type, "forename": $forename, "middleName": $middle_name, "parameters": $parameters, "referenceId": $reference_id, "regTypeId": $reg_type_id, "selfie": $selfie, "significantPersonId": $significant_person_id, "surname": $surname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Finds registrations by the ReferenceId.
#
# GET /api/registrations/referenceid/{referenceId}/summary
# operationId: GetRegistrationSummariesByReferenceId
export def "registrations-referenceid-summary get-registration-summaries" [
  reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<Comments: list<record>, DITFDate: string, DITFStatus: int, bankAccountChecks: list<record>, createdByAgencyUserId: string, creditStatusCheck: record<address: record, ccj: list, checkDate: string, companyDirector: list, hasBeenOverridden: bool, insolvency: list, person: record, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list<record>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list<record>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reference_id: $reference_id} | format pattern "/api/registrations/referenceid/{reference_id}/summary"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Finds a registration by the RegCode.
#
# GET /api/registrations/regcode/{regCode}/summary
# operationId: GetRegistrationSummaryByRegCode
export def "registrations-regcode-summary get" [
  reg_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({reg_code: $reg_code} | format pattern "/api/registrations/regcode/{reg_code}/summary"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets paged registration list by search criteria or nothing if there are no matching fields. Optional parameters may be appended to the query string. Maximum page size is 50.
#
# GET /api/registrations/search
# operationId: GetRegistrationSearch
export def "registrations-search get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --page-num: int # Zero-based page number to retrieve. (format: int32, default: 0)
  --page-size: int # Number of records to return on each request (Maximum value is 50). (format: int32, default: 50)
  --forename: string # Search by forename.
  --surname: string # Search by surname.
  --email: string # Search by user email.
  --dob: string # Date of birth in (yyyy-MM-dd) format
  --apikey: string # ApiKey supplied.
]: nothing -> record<registrationSummaries: table<Comments: list, DITFDate: string, DITFStatus: int, bankAccountChecks: list, createdByAgencyUserId: string, creditStatusCheck: record, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list, idVerification: record, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record, phoneNumber: string, proofOfOwnershipCheck: record, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record, rightToWorkCheck: record, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string>, totalCount: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "pageNum" $page_num "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "forename" $forename "scalar") (serialize-qp "surname" $surname "scalar") (serialize-qp "email" $email "scalar") (serialize-qp "dob" $dob "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/registrations/search" $qp)
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Checks if submitted documents are sufficient to complete registration.
#
# GET /api/registrations/{id}/check-submitted-id-documents
# operationId: CheckSubmittedIdDocuments
export def "registrations-check-submitted-id-documents check" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<checkCode: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/check-submitted-id-documents"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a registration's contact details.
#
# PUT /api/registrations/{id}/contact-details
# operationId: UpdateContactDetails
export def "registrations-contact-details update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  --delivery-method: int@delivery-method-completer # None = 0, Email = 1, Sms = 2 (format: int32)
  --dialling-code: string
  --email: string
  forename: string
  --middle-name: string
  --phone-number: string
  surname: string
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/contact-details"))
  let body = {"deliveryMethod": $delivery_method, "diallingCode": $dialling_code, "email": $email, "forename": $forename, "middleName": $middle_name, "phoneNumber": $phone_number, "surname": $surname} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sets an override for a specific check on the registration.
#
# PUT /api/registrations/{id}/override-check-status
# operationId: OverrideCheckStatus
export def "registrations-override-check-status put" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  check_type: int@check-type-completer-1 # IdDocuments = 1, StandardChecks = 2, InternationalSanctionsAndPep = 3, CreditStatusCheck = 4, BankAccountCheck = 5, ProofOfOwnership = 6, RightToWork = 7, RightToRent = 8 (format: int32)
  comment: string
  status: int@status-completer # Unknown = 0, Pass = 1, Refer = 2, Fail = 3 (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/override-check-status"))
  let body = {"checkType": $check_type, "comment": $comment, "status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns PDF export for a given registration.
#
# GET /api/registrations/{id}/pdf-export
# operationId: GetRegistrationPdfExport
export def "registrations-pdf-export get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/pdf-export"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns a PDF report for a given registration containing specified sections
#
# GET /api/registrations/{id}/pdf-export-sections
export def "registrations-pdf-export-sections get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --comments: oneof<nothing, bool>
  --contact-details: oneof<nothing, bool>
  --standard-checks: oneof<nothing, bool>
  --pep-sanction-checks: oneof<nothing, bool>
  --proof-of-ownership: oneof<nothing, bool>
  --bank-account-check: oneof<nothing, bool>
  --credit-status-check: oneof<nothing, bool>
  --liveness: oneof<nothing, bool>
  --exclude-selfie: oneof<nothing, bool>
  --exclude-id-documents: oneof<nothing, bool>
  --diatf-section: oneof<nothing, bool>
  --apikey: string # ApiKey supplied.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "Comments" $comments "scalar") (serialize-qp "ContactDetails" $contact_details "scalar") (serialize-qp "StandardChecks" $standard_checks "scalar") (serialize-qp "PepSanctionChecks" $pep_sanction_checks "scalar") (serialize-qp "ProofOfOwnership" $proof_of_ownership "scalar") (serialize-qp "BankAccountCheck" $bank_account_check "scalar") (serialize-qp "CreditStatusCheck" $credit_status_check "scalar") (serialize-qp "Liveness" $liveness "scalar") (serialize-qp "ExcludeSelfie" $exclude_selfie "scalar") (serialize-qp "ExcludeIDDocuments" $exclude_id_documents "scalar") (serialize-qp "DIATFSection" $diatf_section "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/pdf-export-sections") $qp)
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Returns settlement status PDF (Share Code) for a given registration.
#
# GET /api/registrations/{id}/pdf-settlement-status
# operationId: GetShareCodePdfExport
export def "registrations-pdf-settlement-status get-share-code-pdf-export" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> string {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/pdf-settlement-status"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resends any invitation for the specified registration.
#
# POST /api/registrations/{id}/resend-invitation
# operationId: ResendInvitation
export def "registrations-resend-invitation post" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/resend-invitation"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets registration settings or nothing if there are no settings associated with the registration.
#
# GET /api/registrations/{id}/settings
# operationId: GetRegistrationSettings
export def "registrations-settings get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/settings"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates registration settings.
#
# PUT /api/registrations/{id}/settings
# operationId: UpdateRegistrationSettings
export def "registrations-settings update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  --capture-personal-details: oneof<nothing, bool>
  --name-match-routine: int@name-match-routine-completer # Fuzzy = 1, Strict = 2 (format: int32)
  --required-checks: list # The value of required checks determines what checks are performed. <br/>Unknown = 0,Id Documents = 1, Standard Checks = 2, International Sanctions and Pep = 3, Credit Status Check = 4, Bank Account Check = 5, Proof of Ownership = 6, Right to Work = 7, Right to Rent = 8<br />
  --skip-email-step: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/settings"))
  let body = {"capturePersonalDetails": $capture_personal_details, "nameMatchRoutine": $name_match_routine, "requiredChecks": $required_checks, "skipEmailStep": $skip_email_step} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Updates the status of the registration to one specified in the request.
#
# PUT /api/registrations/{id}/status
# operationId: UpdateRegistrationStatus
export def "registrations-status update" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  status: int@status-completer-1 # Unknown = 0, Submitted = 1, Approved = 2, Rejected = 3, Exported = 4, Invited = 6 (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/status"))
  let body = {"status": $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Finds a registration by the Id.
#
# GET /api/registrations/{id}/summary
# operationId: GetRegistrationSummary
export def "registrations-summary get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/summary"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of supported id document for the specified registration id.
#
# GET /api/registrations/{id}/supported-id-documents
# operationId: GetRegistrationSupportedIdDocuments
export def "registrations-supported-id-documents get" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<name: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base ({id: $id} | format pattern "/api/registrations/{id}/supported-id-documents"))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves secure links to registration details pages searching by the Reference Id.
#
# POST /api/report-view/by-referenceid
# operationId: GetReportViewByReferenceId
export def "report-view-by-referenceid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  --can-change-status: oneof<nothing, bool>
  --can-verify: oneof<nothing, bool>
  reference_id: string
  --user: string
]: any -> record<results: table<forename: string, surname: string, url: string, validUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/report-view/by-referenceid")
  let body = {"canChangeStatus": $can_change_status, "canVerify": $can_verify, "referenceId": $reference_id, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves secure link to registration details page searching by the Registration Id.
#
# POST /api/report-view/by-registrationid
# operationId: GetReportViewByRegistrationId
export def "report-view-by-registrationid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  --can-change-status: oneof<nothing, bool>
  --can-verify: oneof<nothing, bool>
  registration_id: string # format: uuid
  --user: string
]: any -> record<results: table<forename: string, surname: string, url: string, validUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/report-view/by-registrationid")
  let body = {"canChangeStatus": $can_change_status, "canVerify": $can_verify, "registrationId": $registration_id, "user": $user} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves secure links to web verification pages searching by the Reference Id.
#
# POST /api/web-verifications/by-referenceid
# operationId: GetWebVerificationsByReferenceId
# --returnUrls shape: {returnUrl?: string}
export def "web-verifications-by-referenceid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  reference_id: string
  --return-urls: record # shape: {returnUrl?: string}
]: any -> record<results: table<journeyUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/web-verifications/by-referenceid")
  let body = {"referenceId": $reference_id, "returnUrls": $return_urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieves secure link to web verification page searching by the Registration Id.
#
# POST /api/web-verifications/by-registrationid
# operationId: GetWebVerificationsByRegistrationId
# --returnUrls shape: {returnUrl?: string}
export def "web-verifications-by-registrationid get" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  registration_id: string # format: uuid
  --return-urls: record # shape: {returnUrl?: string}
]: any -> record<results: table<journeyUrl: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/web-verifications/by-registrationid")
  let body = {"registrationId": $registration_id, "returnUrls": $return_urls} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
