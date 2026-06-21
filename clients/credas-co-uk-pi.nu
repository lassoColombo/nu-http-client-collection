# Auto-generated client for Credas API vv1
# Source: https://api.apis.guru/v2/specs/credas.co.uk/pi/v1/openapi.json
# Auth: --token flag or $env.CREDAS_API_TOKEN

const BASE_URL = "http://localhost"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CREDAS_API_TOKEN | default "" }
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
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"accountDetails": $account_details, "address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --company-number: string # The company registration number of the company that should be searched.
  --apikey: string # ApiKey supplied.
]: nothing -> record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "companyNumber" $company_number "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/api/companies" $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"companyNumber": $company_number} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<addressLine1: string, companyName: string, companyNumber: string, dateOfRegistration: string, duplicate: bool, id: string, locality: string, postCode: string, region: string, significantParentCompanies: list<any>, significantPeople: table<forename: string, id: string, regEntryId: string, surname: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($company_id | is-empty) { error make --unspanned { msg: "path parameter 'companyId' must be non-empty" } }
  let full_url = (build-url $base ({company_id: (encode-path-segment $company_id)} | format pattern "/api/companies/{company_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Creates new data check against a specified registration.
#
# POST /api/datachecks
# operationId: AddDataCheck
# --currentAddress shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
export def "datachecks create-data-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
  check_type: int@check-type-completer # The value of checkType dictates what checks are performed. The StandardAml check (value = 1) will check DOB & Mortality. The InternationalPepSanctions check (value = 3) will check just International PEP & Sanctions. The EnhancedAml check (value = 2) will perform both these checks and is equivalent to making two calls with values of 1 then 3 and will be charged accordingly. values=> None = 0, StandardAml = 1, EnhancedAml = 2, InternationalPepSanctions = 3 (format: int32)
  current_address: record # shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
  person: record # shape: {dateOfBirth: string, forename: string, middleName?: string, surname: string}
  reg_entry_id: string # format: uuid
]: any -> record<id: string, regCode: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/datachecks")
  let req_body = {"checkType": $check_type, "currentAddress": $current_address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"documentParameters": $document_parameters, "documentType": $document_type, "imageData": $image_data, "registrationId": $registration_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, hiResUrl: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcFacialUrl: string, nfcReadStatus: int, primaryScanId: string, status: int, surname: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/images/id-document/{registration_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  image_data: string
  registration_id: string # format: uuid
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/images/liveness")
  let req_body = {"imageData": $image_data, "registrationId": $registration_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<base64Data: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/images/liveness-performed/{registration_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<description: string, id: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/images/liveness/{registration_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($scan_id | is-empty) { error make --unspanned { msg: "path parameter 'scanId' must be non-empty" } }
  let full_url = (build-url $base ({scan_id: (encode-path-segment $scan_id)} | format pattern "/api/images/scan-report-pdf/{scan_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"imageData": $image_data, "registrationId": $registration_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<base64Data: string, url: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($registration_id | is-empty) { error make --unspanned { msg: "path parameter 'registrationId' must be non-empty" } }
  let full_url = (build-url $base ({registration_id: (encode-path-segment $registration_id)} | format pattern "/api/images/selfie/{registration_id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates new property registry check against the registration.
#
# POST /api/property-register
# operationId: AddPropertyRegisterCheck
# --address shape: {addressLine1: string, addressLine2?: string, addressLine3?: string, city: string, country: string, county?: string, postcode: string}
# --person shape: {forename: string, middleName?: string, surname: string}
export def "property-register create-check" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"address": $address, "person": $person, "regEntryId": $reg_entry_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves property registry check associated with the registration.
#
# GET /api/property-register/{id}
# operationId: GetPropertyRegisterCheckResult
export def "property-register get-check-result" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/property-register/{id}"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Gets all available RegTypes.
#
# GET /api/reg-types
# operationId: GetAll
export def "reg-types get-list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<id: string, name: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/reg-types")
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Creates new registration.
#
# POST /api/registrations
# operationId: AddRegistration
# --parameters item shape: {key?: string, value?: string}
# --returnUrls shape: {returnUrl?: string}
# --settings shape: {capturePersonalDetails?: bool, nameMatchRoutine?: "1"|"2", requiredChecks?: list<int>, skipEmailStep?: bool}
export def "registrations create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --settings: record # shape: {capturePersonalDetails?: bool, nameMatchRoutine?: "1"|"2", requiredChecks?: list<int>, skipEmailStep?: bool}
  --significant-person-id: string # format: uuid
  surname: string
]: any -> record<id: string, regCode: string, webJourneyUrl: record<url: string, validUntil: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/api/registrations")
  let req_body = {"diallingCode": $dialling_code, "duplicateAcknowledgement": $duplicate_acknowledgement, "emailAddress": $email_address, "forename": $forename, "middleName": $middle_name, "parameters": $parameters, "phoneNumber": $phone_number, "provideWebJourneyLink": $provide_web_journey_link, "referenceId": $reference_id, "regTypeId": $reg_type_id, "returnUrls": $return_urls, "sendEmail": $send_email, "sendSms": $send_sms, "settings": $settings, "significantPersonId": $significant_person_id, "surname": $surname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"document": $document, "documentParameters": $document_parameters, "documentType": $document_type, "forename": $forename, "middleName": $middle_name, "parameters": $parameters, "referenceId": $reference_id, "regTypeId": $reg_type_id, "selfie": $selfie, "significantPersonId": $significant_person_id, "surname": $surname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Finds registrations by the ReferenceId.
#
# GET /api/registrations/referenceid/{referenceId}/summary
# operationId: GetRegistrationSummariesByReferenceId
export def "registrations-referenceid-summary get-summaries-by-reference" [
  reference_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> table<Comments: list<record>, DITFDate: string, DITFStatus: int, bankAccountChecks: list<record>, createdByAgencyUserId: string, creditStatusCheck: record<address: record, ccj: list, checkDate: string, companyDirector: list, hasBeenOverridden: bool, insolvency: list, person: record, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: list<record>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: list<record>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reference_id | is-empty) { error make --unspanned { msg: "path parameter 'referenceId' must be non-empty" } }
  let full_url = (build-url $base ({reference_id: (encode-path-segment $reference_id)} | format pattern "/api/registrations/referenceid/{reference_id}/summary"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Finds a registration by the RegCode.
#
# GET /api/registrations/regcode/{regCode}/summary
# operationId: GetRegistrationSummaryByRegCode
export def "registrations-regcode-summary get-by-reg-code" [
  reg_code: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($reg_code | is-empty) { error make --unspanned { msg: "path parameter 'regCode' must be non-empty" } }
  let full_url = (build-url $base ({reg_code: (encode-path-segment $reg_code)} | format pattern "/api/registrations/regcode/{reg_code}/summary"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"pageNum": $page_num, "pageSize": $page_size, "forename": $forename, "surname": $surname, "email": $email, "dob": $dob} | compact), body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<checkCode: int, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/check-submitted-id-documents"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/contact-details"))
  let req_body = {"deliveryMethod": $delivery_method, "diallingCode": $dialling_code, "email": $email, "forename": $forename, "middleName": $middle_name, "phoneNumber": $phone_number, "surname": $surname} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sets an override for a specific check on the registration.
#
# PUT /api/registrations/{id}/override-check-status
# operationId: OverrideCheckStatus
export def "registrations-override-check-status check" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  check_type: int@check-type-completer-1 # IdDocuments = 1, StandardChecks = 2, InternationalSanctionsAndPep = 3, CreditStatusCheck = 4, BankAccountCheck = 5, ProofOfOwnership = 6, RightToWork = 7, RightToRent = 8 (format: int32)
  comment: string
  status: int@status-completer # Unknown = 0, Pass = 1, Refer = 2, Fail = 3 (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/override-check-status"))
  let req_body = {"checkType": $check_type, "comment": $comment, "status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/pdf-export"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let qp = [(serialize-qp "Comments" $comments "scalar") (serialize-qp "ContactDetails" $contact_details "scalar") (serialize-qp "StandardChecks" $standard_checks "scalar") (serialize-qp "PepSanctionChecks" $pep_sanction_checks "scalar") (serialize-qp "ProofOfOwnership" $proof_of_ownership "scalar") (serialize-qp "BankAccountCheck" $bank_account_check "scalar") (serialize-qp "CreditStatusCheck" $credit_status_check "scalar") (serialize-qp "Liveness" $liveness "scalar") (serialize-qp "ExcludeSelfie" $exclude_selfie "scalar") (serialize-qp "ExcludeIDDocuments" $exclude_id_documents "scalar") (serialize-qp "DIATFSection" $diatf_section "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/pdf-export-sections") $qp)
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"Comments": $comments, "ContactDetails": $contact_details, "StandardChecks": $standard_checks, "PepSanctionChecks": $pep_sanction_checks, "ProofOfOwnership": $proof_of_ownership, "BankAccountCheck": $bank_account_check, "CreditStatusCheck": $credit_status_check, "Liveness": $liveness, "ExcludeSelfie": $exclude_selfie, "ExcludeIDDocuments": $exclude_id_documents, "DIATFSection": $diatf_section} | compact), body: null}
}

# Returns settlement status PDF (Share Code) for a given registration.
#
# GET /api/registrations/{id}/pdf-settlement-status
# operationId: GetShareCodePdfExport
export def "registrations-pdf-settlement-status get-share-code-export" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/pdf-settlement-status"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Resends any invitation for the specified registration.
#
# POST /api/registrations/{id}/resend-invitation
# operationId: ResendInvitation
export def "registrations-resend-invitation resend" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/resend-invitation"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/settings"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  --capture-personal-details: oneof<nothing, bool>
  --name-match-routine: int@name-match-routine-completer # Fuzzy = 1, Strict = 2 (format: int32)
  --required-checks: list<int> # The value of required checks determines what checks are performed. Unknown = 0,Id Documents = 1, Standard Checks = 2, International Sanctions and Pep = 3, Credit Status Check = 4, Bank Account Check = 5, Proof of Ownership = 6, Right to Work = 7, Right to Rent = 8
  --skip-email-step: oneof<nothing, bool>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/settings"))
  let req_body = {"capturePersonalDetails": $capture_personal_details, "nameMatchRoutine": $name_match_routine, "requiredChecks": $required_checks, "skipEmailStep": $skip_email_step} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --apikey: string # ApiKey supplied.
  status: int@status-completer-1 # Unknown = 0, Submitted = 1, Approved = 2, Rejected = 3, Exported = 4, Invited = 6 (format: int32)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/status"))
  let req_body = {"status": $status} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<Comments: table<checkType: int, comment: string, dateCreated: string, id: string, name: string, type: int>, DITFDate: string, DITFStatus: int, bankAccountChecks: table<Address1: string, City: string, Forename: string, MiddleName: string, PostCode: string, Surname: string, accountNumber: string, accountNumberValidation: int, accountNumberValidationText: string, accountStatus: int, accountStatusText: string, accountValid: bool, addressValidation: int, addressValidationText: string, checkDate: string, checkId: string, checkStatus: int, error: bool, hasBeenOverridden: bool, nameValidation: int, nameValidationText: string, referenceId: string, sortcode: string, sortcodeValidation: int, sortcodeValidationText: string>, createdByAgencyUserId: string, creditStatusCheck: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, ccj: list<record>, checkDate: string, companyDirector: list<record>, hasBeenOverridden: bool, insolvency: list<record>, person: record<dateOfBirth: string, forename: string, middleName: string, surname: string>, status: int>, customTermsAccepted: bool, customTermsAcceptedDateTime: string, customTermsAcceptedVersion: int, dataCheckResult: int, dataCheckSources: table<address: record, dateCreated: string, hasBeenOverridden: bool, hasPepSanctionsData: bool, label: string, pepSanctionsData: list, person: record, remarks: list, sourceType: int, status: int>, dataChecksPerformed: bool, dateCompleted: string, dateCreated: string, email: string, forename: string, hasLivenessPerformed: bool, hasSelfie: bool, id: string, idDocuments: table<addressCity: string, addressFull: string, addressPostcode: string, country: string, countryCode: string, dateCreated: string, dateOfBirth: string, description: string, documentAnalysisResult: int, documentNumber: string, documentSide: int, expiryDate: string, facialMatch: bool, forename: string, fullName: string, id: string, isUnderReview: bool, manuallyVerified: bool, middleName: string, mrz1: string, mrz2: string, mrz3: string, nameCheck: bool, nameCheckMethod: int, nfcCheck: bool, nfcReadStatus: int, primaryScanId: string, status: int, surname: string>, idVerification: record<checkStatus: int, hasBeenOverridden: bool>, isAgentLed: bool, livenessMethod: int, livenessStatus: int, livenessVerified: bool, middleName: string, personalDetails: record<address: record<addressLine1: string, addressLine2: string, addressLine3: string, city: string, country: string, county: string, postcode: string>, dateOfBirth: string, forename: string, surname: string>, phoneNumber: string, proofOfOwnershipCheck: record<checkStatus: int, hasBeenOverridden: bool, matchResult: int, matchResultText: string, propertyOwnership: int, propertyOwnershipText: string, titleNumber: string>, referenceId: string, regCode: string, regTypeId: string, rightToRentCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkCheck: record<checkStatus: int, hasBeenOverridden: bool, hasShareCodePdf: bool, shareCodeFacialMatchStatus: int, shareCodeNameCheckStatus: int>, rightToWorkDocumentsProvided: int, safeHarbourVerifiedDate: string, safeHarbourVerifiedStatus: int, status: int, surname: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/summary"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
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
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accept: string@accept-completer # Response content type
  --apikey: string # ApiKey supplied.
]: nothing -> record<name: string, type: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/api/registrations/{id}/supported-id-documents"))
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Retrieves secure links to registration details pages searching by the Reference Id.
#
# POST /api/report-view/by-referenceid
# operationId: GetReportViewByReferenceId
export def "report-view-by-referenceid get-reference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"canChangeStatus": $can_change_status, "canVerify": $can_verify, "referenceId": $reference_id, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves secure link to registration details page searching by the Registration Id.
#
# POST /api/report-view/by-registrationid
# operationId: GetReportViewByRegistrationId
export def "report-view-by-registrationid get-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"canChangeStatus": $can_change_status, "canVerify": $can_verify, "registrationId": $registration_id, "user": $user} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves secure links to web verification pages searching by the Reference Id.
#
# POST /api/web-verifications/by-referenceid
# operationId: GetWebVerificationsByReferenceId
# --returnUrls shape: {returnUrl?: string}
export def "web-verifications-by-referenceid get-reference" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"referenceId": $reference_id, "returnUrls": $return_urls} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Retrieves secure link to web verification page searching by the Registration Id.
#
# POST /api/web-verifications/by-registrationid
# operationId: GetWebVerificationsByRegistrationId
# --returnUrls shape: {returnUrl?: string}
export def "web-verifications-by-registrationid get-registration" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  let req_body = {"registrationId": $registration_id, "returnUrls": $return_urls} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = ($accept | default "application/json")
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  let extra_headers = {"apikey": $apikey} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
