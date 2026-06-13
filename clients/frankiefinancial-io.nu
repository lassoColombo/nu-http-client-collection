# Auto-generated client for Frankie Financial API v1.5.3
# Source: https://api.apis.guru/v2/specs/frankiefinancial.io/1.5.3/swagger.json
# Auth: --token flag or $env.FRANKIE_FINANCIAL_API_TOKEN

const BASE_URL = "https://api.demo.frankiefinancial.io/compliance/v1.2"
const DEFAULT_AUTH = "api_key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o FRANKIE_FINANCIAL_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "api_key" => { {headers: {api_key: $token_val}, query: ""} }
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

def base-url-completer [] { ["https://api.demo.frankiefinancial.io/compliance/v1.2"] }
def auth-scheme-completer [] { ["api_key"] }

# Completers for enum parameters
def resultLevel-completer [] { ["full" "summary"] }
def validation-completer [] { ["acn" "off" "on" "only"] }
def entityType-completer [] { ["INDIVIDUAL" "ORGANISATION" "TRUST"] }
def gender-completer [] { ["F" "M" "O" "U"] }
def documentStatus-completer [] { ["DOC_CHECKED" "DOC_SCANNED" "INITIALISING" "SCAN_IN_PROGRESS"] }
def idType-completer [] { ["ANNUAL_RETURN" "ATTESTATION" "BANK_ACCOUNT" "BANK_STATEMENT" "BIRTH_CERT" "CHARGES" "CHECK_RESULTS" "CITIZENSHIP" "CONCESSION" "DEATH_CERT" "DEVICE" "DRIVERS_LICENCE" "EMAIL_ADDRESS" "EXTERNAL_ADMIN" "HEALTH_CONCESSION" "IMMIGRATION" "INTENT_PROOF" "MARRIAGE_CERT" "MILITARY_ID" "MOBILE_PHONE" "MSISDN" "NAME_CHANGE" "NATIONAL_HEALTH_ID" "NATIONAL_ID" "OTHER" "PASSPORT" "PENSION" "PRE_ASIC" "REPORT" "SELF_IMAGE" "TAX_ID" "UTILITY_BILL" "VEHICLE_REGISTRATION" "VISA"] }
def status-completer [] { ["FALSE_POSITIVE" "STALE" "TRUE_POSITIVE" "TRUE_POSITIVE_ACCEPT" "TRUE_POSITIVE_REJECT" "UNKNOWN"] }
def set-completer [] { ["archived" "clear" "fail" "inactive" "wait"] }
def risk-completer [] { ["high" "low" "medium" "significant" "unacceptable"] }
def payload-completer [] { ["object" "string"] }
def functionResult-completer [] { ["COMPLETED" "FAILED" "INCOMPLETE"] }
def notificationType-completer [] { ["ALERT" "EVENT" "FUNCTION" "RESULT"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-international-profile InternationalBusinessProfile" } } | get name | first)
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

# Retrieve a business profile from any country (AUS included).
#
# POST /business/international/profile
# operationId: InternationalBusinessProfile
export def "business-international-profile InternationalBusinessProfile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --company-code: string # This is the company number returned in the search results  (InternationalBusinessSearchResponse.Companies.CompanyDTO[n].Code)
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for:    - The United States which requires the state registry to query as well.     - As an example, for a Delaware query, the country code would be "US-DE".     - A Texas query would use "US-TX"   - Canada, which also requires you to supply a territory code too.     - A Yukon query would use CA-YU, Manitoba would use CA-MB     - You can do an all jurisdiction search with CA-ALL   - United Arab Emirates (UAE)     - For Abu Dhabi, use "DI"      - For Dubai, use "DU"    See details here:     https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business/international/profile")
  let body = {company_code: $company_code, country: $country} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for a business from any country (AUS included).
#
# POST /business/international/search
# operationId: InternationalBusinessSearch
export def "business-international-search InternationalBusinessSearch" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO 3166-1 alpha2 country code of country registry you wish to search. This is consistent for all countries except for:    - The United States which requires the state registry to query as well.     - As an example, for a Delaware query, the country code would be "US-DE".     - A Texas query would use "US-TX"   - Canada, which also requires you to supply a territory code too.     - A Yukon query would use CA-YU, Manitoba would use CA-MB     - You can do an all jurisdiction search with CA-ALL   - United Arab Emirates (UAE)     - For Abu Dhabi, use "DI"      - For Dubai, use "DU"    See details here:     https://apidocs.frankiefinancial.com/docs/country-codes-for-international-business-queries
  --organisation-name: string # Name or name fragment you wish to search for.   Note: The less you supply, the more, but less relevant results will be returned.  CRITICAL NOTE: This is *NOT* to be used as a progressive search function.  You must supply at least one of organisation_name and/or organisation_number. If you supply both, a name search will be conducted first, then the number will be checked against the result set and any remaining results returned.
  --organisation-number: string # The business number you wish to search on. This should be a unique corporate identifier as per the country registry you're searching.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/business/international/search")
  let body = {country: $country, organisation_name: $organisation_name, organisation_number: $organisation_number} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Business Entity and Query UBO (AUS Only)
#
# POST /business/ownership/query
# operationId: BusinessOwnershipQuery
# --organisation shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "business-ownership-query BusinessOwnershipQuery" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkType: list # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category.    The checkType is make up of a comma separated list of the types of check we wish to run.  The order is important, and must be of the form:   - Entity Check (if you're running this). Choose one from the available options   - ID Check (If you want this)   - PEP Checks (again if you want this, choose one of the options)  Entity Checks - One of:   - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1)   - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2)  ID Checks - One of:   - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more.    Fraud Checks - One or more  of:   - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed.   - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet)    PEP Checks - One of:   - "pep": Will only run PEP/Sanctions checks (no identity verification)   - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification)      * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested.    Pre-defined combinations:   - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation.   - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation.  Custom:   - By arrangement with Frankie you can define your own KYC check type.      This will allow you to set the minimum number of matches for:     - name      - date of birth     - address     - government id      This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too).    Profile:   - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles.      The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use.      Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features.   They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process.      Entity Profiles are the future of checks with Frankie Financial.
  --entityCategories: list # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked.    - organisation - Just the organisation itself.   - ubos - All ultimate beneficial owners.   - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category.   - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership.   - officers - All officers of the company   - officers_directors - All directors of the company   - officers_other - All non-director officers of the company   - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --resultLevel: string@resultLevel-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full.  (default: summary)
  --validation: string@validation-completer # Should a validation check be run before the ownership query. The default is specified via configuration. The validation checks to see if the provided organisation is suitable for an ownership query by looking for the ACN in public data sources.  Options are: - "on": Validate only when ACN is not provided. This is the typical default. - "acn": Validate even if ACN is provided. - "only": Like "acn" but only do validation query, don't proceed with ownership query. This option cannot be set as the default via configuration. - "off": Never validate. The Ownership query will then fail if an ACN is not provided.
  --generateReport: string # The type of human readable report, if any, to generate based on the ownership query results.
  --includeHistorical: oneof<nothing, bool> # If set to true, historical ownership data will be requested.
  --onlyProfile: oneof<nothing, bool> # If set to true, a full UBO report will not be requested.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  organisation: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkType" $checkType "csv") (serialize-qp "entityCategories" $entityCategories "csv") (serialize-qp "resultLevel" $resultLevel "scalar") (serialize-qp "validation" $validation "scalar") (serialize-qp "generateReport" $generateReport "scalar") (serialize-qp "includeHistorical" $includeHistorical "scalar") (serialize-qp "onlyProfile" $onlyProfile "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business/ownership/query" $qp)
  let body = {organisation: $organisation} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run Report(s) against a new or existing organisation entity (AUS Only).
#
# POST /business/reports
# operationId: RunBusinessReports
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "business-reports RunBusinessReports" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --reportTypes: string # Define the report(s) you wish to run.  You can request more than one as a comma separated list.  Duplicates will be ignored.  Note: These reports are different to the business details and UBO queries and are meant to provide deeper detail and background on a business or organisation.    Current valid report types are:   - creditScore   - creditReport
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --dateOfBirth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entityId: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entityProfile: string # If the entity is using the new profiles feature, then their profile name will be found here.  Note: If setting a profile, you must ensure that the profile matches a known configuration.  Please contact Frankie developer support if you're unsure as to what valid values are.
  --entityType: string@entityType-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extraData: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added.  See here for more information about possible values you can use:   https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing.  Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale  - "F"emale - "U"nspecified - "O"ther (for want of a better option)  (e.g. F)
  --identityDocs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisationData: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "reportTypes" $reportTypes "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/business/reports" $qp)
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, entityId: $entityId, entityProfile: $entityProfile, entityType: $entityType, extraData: $extraData, flags: $flags, gender: $gender, identityDocs: $identityDocs, name: $name, organisationData: $organisationData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Run KYC/AML Checks on Organisation and/or Associated Individuals.
#
# POST /business/{entityId}/verify
# operationId: CheckOrganisation
export def "business-verify CheckOrganisation" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkType: list # When creating a new check, we need to define the checks we wish to run. If this parameter is not supplied then the check will be based on a configured check type for each entity category.    The checkType is make up of a comma separated list of the types of check we wish to run.  The order is important, and must be of the form:   - Entity Check (if you're running this). Choose one from the available options   - ID Check (If you want this)   - PEP Checks (again if you want this, choose one of the options)  Entity Checks - One of:   - "one_plus": Checks name, address and DoB against a minimum of 1 data source. (also known as a 1+1)   - "two_plus": Checks name, address and DoB against a minimum of 2 independent data sources (also known as a 2+2)  ID Checks - One of:   - "id": Checks all of the identity documents, but not necessarily the entity itself independently. Use this in conjunction with a one_plus or two_plus for more.    Fraud Checks - One or more  of:   - "fraudlist": Checks to see if the identity appears on any known fraud lists. Should be run after KYC/ID checks have passed.   - "fraudid": Checks external ID services to see if details appear in fraud detection services (e.g. EmailAge or FraudNet)    PEP Checks - One of:   - "pep": Will only run PEP/Sanctions checks (no identity verification)   - "pep_media": Will run PEP/Sanctions checks, as well as watchlist and adverse media checks. (no identity verification)      * NOTE: These checks will ONLY run if either the KYC/ID checks have been run prior, or it is the only check requested.    Pre-defined combinations:   - "full": equivalent to "two_plus,id,pep_media" or "pep_media" if the target is an organisation.   - "default": Currently defined as "two_plus,id" or "pep" if the target is an organisation.  Custom:   - By arrangement with Frankie you can define your own KYC check type.      This will allow you to set the minimum number of matches for:     - name      - date of birth     - address     - government id      This allows for alternatives to the "standard" two_plus or one_plus (note, these can be overridden too).    Profile:   - "profile": By arrangement with Frankie you can have a "profile" check type that applies checks according to a profile that you assign to the entity from a predefined set of profiles.      The profile to use will be taken from the entity.entityProfile field if set, or be run through a set of configurable rules to determine which one to use.      Profiles act a little like the Pre-defined combinations above in that they can map to a defined list. But they offer a lot more besides, including rules for determining default settings, inbuild data aging and other configurable features.   They also allow for a new result set top be returned that provides a more detailed and useful breakdown of the check/verification process.      Entity Profiles are the future of checks with Frankie Financial.
  --entityCategories: list # A comma separated list that specifies the categories of entities associated with the target organisation that will be checked.    - organisation - Just the organisation itself.   - ubos - All ultimate beneficial owners.   - pseudo_ubos - Use an alterntive category when an organisation has no actual UBOs. The actual category to use is defined via configuration, default is no alterntive category.   - direct_owners - All direct owners of the company, both organisations and individuals, may include UBOs for for simple ownership.   - officers - All officers of the company   - officers_directors - All directors of the company   - officers_other - All non-director officers of the company   - all - All direct and indirect owners, both organisations and individuals (including UBOs), and officers of all organisations.
  --resultLevel: string@resultLevel-completer # The result level allows you to specify the level of detail returned for the entity check. You can choose summary or full.  (default: summary)
  --generateReport: string # The type of human readable report, if any, to generate based on the ownership query results.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "checkType" $checkType "csv") (serialize-qp "entityCategories" $entityCategories "csv") (serialize-qp "resultLevel" $resultLevel "scalar") (serialize-qp "generateReport" $generateReport "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/business/($entityId)/verify" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create New Document.
#
# POST /document
# operationId: CreateDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document CreateDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document")
  let body = {country: $country, docScan: $docScan, documentId: $documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Document and Compare to Original.
#
# POST /document/new/compare
# operationId: CompareDocument
# --compareDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --toDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
export def "document-new-compare CompareDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compareDocument: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --toDocument: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/compare")
  let body = {compareDocument: $compareDocument, toDocument: $toDocument} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create and OCR Scan Document.
#
# POST /document/new/scan
# operationId: CreateScanDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document-new-scan CreateScanDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/scan")
  let body = {country: $country, docScan: $docScan, documentId: $documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Document and Run Utility Price Comparison.
#
# POST /document/new/utility/process/compare
# operationId: CreateProcessIndustryUtilityDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document-new-utility-process-compare CreateProcessIndustryUtilityDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --planLimit: int # The maximum number of plans to return (default: 30)
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planLimit" $planLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/document/new/utility/process/compare" $qp)
  let body = {country: $country, docScan: $docScan, documentId: $documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create and Verify Document.
#
# POST /document/new/verify
# operationId: VerifyDocument
# --document shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --entityData shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "document-new-verify VerifyDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --entityData: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/new/verify")
  let body = {document: $document, entityData: $entityData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search For a Document !! EXPERIMENTAL !!
#
# POST /document/search
# operationId: SearchDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document-search SearchDocument" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/document/search")
  let body = {country: $country, docScan: $docScan, documentId: $documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Document.
#
# DELETE /document/{documentId}
# operationId: DeleteDocument
export def "document DeleteDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Document Details
#
# GET /document/{documentId}
# operationId: QueryDocument
export def "document QueryDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Existing Document.
#
# POST /document/{documentId}
# operationId: UpdateDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document UpdateDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --noInvalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --body-documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "noInvalidate" $noInvalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/document/($documentId)" $qp)
  let body = {country: $country, docScan: $docScan, documentId: $body_documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Document Verification Check Details.
#
# GET /document/{documentId}/checks
# operationId: QueryDocumentChecks
export def "document-checks QueryDocumentChecks" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/checks")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Document and Compare to Original.
#
# POST /document/{documentId}/compare
# operationId: UpdateCompareDocument
# --compareDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --toDocument shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
export def "document-compare UpdateCompareDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --compareDocument: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --toDocument: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/compare")
  let body = {compareDocument: $compareDocument, toDocument: $toDocument} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Retrieve Document and Scan Data
#
# GET /document/{documentId}/full
# operationId: QueryDocumentFull
export def "document-full QueryDocumentFull" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/full")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update and OCR Scan Document
#
# POST /document/{documentId}/scan
# operationId: UpdateScanDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document-scan UpdateScanDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --body-documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/scan")
  let body = {country: $country, docScan: $docScan, documentId: $body_documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Document and Run Utility Price Comparison.
#
# POST /document/{documentId}/utility/process/compare
# operationId: UpdateProcessIndustryUtilityDocument
# --docScan item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
export def "document-utility-process-compare UpdateProcessIndustryUtilityDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --planLimit: int # The maximum number of plans to return (default: 30)
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  country: string # The ISO-3166-alpha3 country code of the issuing national. Once set, this cannot be changed.  See https://en.wikipedia.org/wiki/List_of_ISO_3166_country_codes for more  (e.g. AUS)
  --docScan: list # Collection of one or more objects that describe scan(s) that need to be put through OCR or facial recognition. These should all be from the one ID document, such as front/back, or page 1, 2, 3, etc. You can upload multiple scans in a single call, or in multiple calls.     Note: if you do upload over multiple calls, make sure you include the documentId (see above), and indicate that this is happening with a "more_data" checkAction — item shape: {ScanDelete?: bool, scanCreated?: string, scanData?: string, scanDataRetrievalState?: "NORMAL"|"EXCLUDED"|"FAILED", scanDocId?: string, scanFilename?: string, scanMIME?: "image/jpeg"|"image/png"|"image/gif"|"image/webp"|"image/tiff"|"image/bmp"|"application/zip"|"application/x-tar"|"application/x-rar-compressed"|"application/gzip"|"application/x-bzip2"|"application/x-7z-compressed"|"application/pdf"|"application/rtf"|"application/postscript"|"application/json"|"audio/mpeg"|"audio/m4a"|"audio/x-wav"|"audio/amr"|"application/msword"|"application/vnd.openxmlformats-officedocument.wordprocessingml.document"|"application/vnd.ms-excel"|"application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"|"application/vnd.ms-powerpoint"|"application/vnd.openxmlformats-officedocument.presentationml.presentation"|"video/mp4"|"video/webm"|"video/quicktime"|"video/x-msvideo"|"video/x-ms-wmv"|"video/mpeg", scanPageNum?: int, scanSide?: "F"|"B", scanType?: "PHOTO"|"VIDEO"|"AUDIO"|"PDF"|"DOC"|"ZIP"}
  --body-documentId: string # When an ID document is created/uploaded, it is assigned a documentId. You'll see this in a successful response or successfully accepted response. This can then be referenced in subsequent calls if you're uploading more/updated data.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --documentStatus: string@documentStatus-completer # Current status of a document. - "INITIALISING": the state whilst you're uploading and updating - "SCAN_IN_PROGRESS": the state whilst it's being scanned.  - "DOC_SCANNED": the document has been scanned and data extracted as best as possible. It's still possible to update the details and add more scans if you wish. - "DOC_CHECKED": the document has been used as part of a check that has been finalised in some way. You can no longer update this document and any attempt will generate an error.  (e.g. DOC_SCANNED)
  --extraData: list # Set of key-value pairs that provide ID type-specific data. If updating an existing document, then existing values with the same name will be overwritten. New values will be added.  If this document is scanned through OCR or similar processes, then extracted data will be found here (Some may be used to populate other fields like idNumber and idExpiry as well) — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --idExpiry: string # The expiry date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 2020-02-01)
  --idIssued: string # The issued date of the document (if known) in YYYY-MM-DD format. (format: date, e.g. 1972-11-04)
  --idNumber: string # The ID number of the document (if known). (e.g. 123456789)
  --idSubType: string # The sub-type of identity document. Very document specific.
  idType: string@idType-completer # Valid ID types   - "OTHER": Generic document type. Unspecified.   - "DRIVERS_LICENCE": Driver's licence.   - "PASSPORT": Passport   - "VISA": Visa document (not Visa payment card)   - "IMMIGRATION": Immigration card   - "NATIONAL_ID": Any national ID card   - "TAX_ID": Any national tax identifier   - "NATIONAL_HEALTH_ID": Any national health program ID card (e.g. Medicare, NHS)   - "CONCESSION": State issued concession card   - "HEALTH_CONCESSION": State issued health specific concession card   - "PENSION": State issued pension ID   - "MILITARY_ID": Military ID   - "BIRTH_CERT": Birth certificate   - "CITIZENSHIP": Citizenship certificate   - "MARRIAGE_CERT": Marriage certificate   - "DEATH_CERT": Death certificate   - "NAME_CHANGE": Name chage confirmation   - "UTILITY_BILL": Regulated utility bill, such as electricity, gas, etc   - "BANK_STATEMENT": Bank/card statement   - "BANK_ACCOUNT": Bank account   - "INTENT_PROOF": A proof of intent. Generally a photo/video, or a scanned letter   - "ATTESTATION": A document of attestation (e.g. Statutory Declaration)   - "SELF_IMAGE": A "selfie" used for comparisions   - "EMAIL_ADDRESS": An email address   - "MSISDN": A mobile phone number   - "DEVICE": A device ID   - "VEHICLE_REGISTRATION": Vehicle registration number Business related documentation   - "EXTERNAL_ADMIN": Details of appointed administrator.   - "CHARGES": Details of any charges that have been laid against a company or director   - "PRE_ASIC": Any documents that are Pre-ASIC   - "ANNUAL_RETURN": Details of a company's annual return   - "REPORT": Frankie generated report. Special document types   - "CHECK_RESULTS": A special document type for specifying results of checks completed other than through Frankie.  (e.g. DRIVERS_LICENCE)
  --region: string # Regional variant of the ID (e.g. VIC drivers licence)  You should always use the local abbreviation for this. E.g.   - VIC for The Australian state of Victoria   - MA for the US state of Massachusetts   - etc  (e.g. VIC)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "planLimit" $planLimit "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/document/($documentId)/utility/process/compare" $qp)
  let body = {country: $country, docScan: $docScan, documentId: $body_documentId, documentStatus: $documentStatus, extraData: $extraData, idExpiry: $idExpiry, idIssued: $idIssued, idNumber: $idNumber, idSubType: $idSubType, idType: $idType, region: $region} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Provide Explicit Consent to Switch Utility Plans.
#
# POST /document/{documentId}/utility/process/consent
# operationId: UpdateProcessIndustryUtilityDocumentConsent
# --details shape: {concessionCard?: record, vulnerabilities?: record}
export def "document-utility-process-consent UpdateProcessIndustryUtilityDocumentConsent" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  correlationId: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  --details: record # Information for the residents of the property being supplied — shape: {concessionCard?: record, vulnerabilities?: record}
  planId: string # Unique ID of plan, selected from comparison results (format: string, e.g. 123456)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/utility/process/consent")
  let body = {correlationId: $correlationId, details: $details, planId: $planId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Initiate Switching of Utility Plan.
#
# POST /document/{documentId}/utility/process/switch
# operationId: UpdateProcessIndustryUtilityDocumentSwitch
# --details shape: {customerDetails: record}
export def "document-utility-process-switch UpdateProcessIndustryUtilityDocumentSwitch" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --confirmation: list # Array of strings containing all the keys of the elements that required confirmation in the EIC. The absence of any key for a mandatory confirmation will result in an error response.
  correlationId: string # Correlation ID as passed to comparison request (format: uuid, e.g. d290f1ee-6c54-4b01-90e6-d701748f0851)
  details: record # Details required to switch retailers — shape: {customerDetails: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/utility/process/switch")
  let body = {confirmation: $confirmation, correlationId: $correlationId, details: $details} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update and Verify Document.
#
# POST /document/{documentId}/verify
# operationId: UpdateVerifyDocument
# --document shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --entityData shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "document-verify UpdateVerifyDocument" [
  documentId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --document: record # shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --entityData: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/document/($documentId)/verify")
  let body = {document: $document, entityData: $entityData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create New Entity.
#
# POST /entity
# operationId: CreateEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity CreateEntity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --dateOfBirth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entityId: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entityProfile: string # If the entity is using the new profiles feature, then their profile name will be found here.  Note: If setting a profile, you must ensure that the profile matches a known configuration.  Please contact Frankie developer support if you're unsure as to what valid values are.
  --entityType: string@entityType-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extraData: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added.  See here for more information about possible values you can use:   https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing.  Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale  - "F"emale - "U"nspecified - "O"ther (for want of a better option)  (e.g. F)
  --identityDocs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisationData: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity")
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, entityId: $entityId, entityProfile: $entityProfile, entityType: $entityType, extraData: $extraData, flags: $flags, gender: $gender, identityDocs: $identityDocs, name: $name, organisationData: $organisationData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Entity and Get IDV Token
#
# POST /entity/new/idvalidate/getToken
# operationId: CreateEntityGetIDVToken
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-idvalidate-get-token CreateEntityGetIDVToken" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --applicantId: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --applicationId: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset.  You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service  You must send either a referrer or an applicationID (see above)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity/new/idvalidate/getToken")
  let body = {applicantId: $applicantId, applicationId: $applicationId, entity: $entity, referrer: $referrer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Entity and Push Self-Verification Link
#
# POST /entity/new/verify/pushToMobile
# operationId: CreateCheckEntityPushToMobile
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-verify-push-to-mobile CreateCheckEntityPushToMobile" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --deviceCheckDetails: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nopush" $nopush "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/entity/new/verify/pushToMobile" $qp)
  let body = {deviceCheckDetails: $deviceCheckDetails, entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create and Verify Entity
#
# POST /entity/new/verify/{checkType}/{resultLevel}
# operationId: CreateCheckEntity
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-new-verify CreateCheckEntity" [
  checkType: string
  resultLevel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --deviceCheckDetails: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/new/verify/($checkType)/($resultLevel)")
  let body = {deviceCheckDetails: $deviceCheckDetails, entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Search for Entity
#
# POST /entity/search
# operationId: SearchEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity-search SearchEntity" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --dateOfBirth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --entityId: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entityProfile: string # If the entity is using the new profiles feature, then their profile name will be found here.  Note: If setting a profile, you must ensure that the profile matches a known configuration.  Please contact Frankie developer support if you're unsure as to what valid values are.
  --entityType: string@entityType-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extraData: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added.  See here for more information about possible values you can use:   https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing.  Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale  - "F"emale - "U"nspecified - "O"ther (for want of a better option)  (e.g. F)
  --identityDocs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisationData: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/entity/search")
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, entityId: $entityId, entityProfile: $entityProfile, entityType: $entityType, extraData: $extraData, flags: $flags, gender: $gender, identityDocs: $identityDocs, name: $name, organisationData: $organisationData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete Entity
#
# DELETE /entity/{entityId}
# operationId: DeleteEntity
export def "entity DeleteEntity" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Entity Details
#
# GET /entity/{entityId}
# operationId: QueryEntity
export def "entity QueryEntity" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Existing Entity.
#
# POST /entity/{entityId}
# operationId: UpdateEntity
# --addresses item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
# --dateOfBirth shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
# --extraData item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
# --flags item shape: {flag?: string, value?: int}
# --identityDocs item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
# --name shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
# --organisationData shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
export def "entity UpdateEntity" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --noInvalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --addresses: list # Collection of address objects. — item shape: {addressId?: string, addressType?: "OTHER"|"RESIDENTIAL"|"RESIDENTIAL1"|"RESIDENTIAL2"|"RESIDENTIAL3"|"RESIDENTIAL4"|"BUSINESS"|"POSTAL"|"REGISTERED_OFFICE"|"PLACE_OF_BUSINESS"|"OFFICIAL_CORRESPONDANCE", buildingName?: string, careOf?: string, country: string, endDate?: string, longForm?: string, postalCode?: string, region?: string, startDate?: string, state?: string, streetName?: string, streetNumber?: string, streetType?: string, suburb?: string, town?: string, unitNumber?: string}
  --dateOfBirth: record # shape: {country?: string, dateOfBirth?: string, locality?: string, yearOfBirth?: string}
  --body-entityId: string # When an entity is first created, it is assigned an ID. When updating an entity, make sure you set the entityId One exception to this is when an entity is created from a document object. It is expected that this object would be passed into a /check or /entity call to set it.  (format: uuid, e.g. 84a9a860-68ae-4d7d-9a53-54a1116d5051)
  --entityProfile: string # If the entity is using the new profiles feature, then their profile name will be found here.  Note: If setting a profile, you must ensure that the profile matches a known configuration.  Please contact Frankie developer support if you're unsure as to what valid values are.
  --entityType: string@entityType-completer # Indicates the type of an entity. - "INDIVIDUAL": An individual. - "TRUST": A trust. - "ORGANISATION": An organisation.
  --extraData: list # Set of key-value pairs that provide arbitrary additional type-specific data. You can use these fields to store external IDs, or other non-identity related items if you need to. If updating an existing entity, then existing values with the same name will be overwritten. New values will be added.  See here for more information about possible values you can use:   https://apidocs.frankiefinancial.com/docs/entity-extradata-key-value-pairs — item shape: {kvpKey?: string, kvpType?: "defunct"|"general.string"|"general.integer"|"general.float"|"general.bool"|"general.date"|"general.datetime"|"raw.json.base64"|"raw.xml.base64"|"raw.base64"|"error.code"|"error.message"|"result.code"|"result.id"|"id.external"|"id.number.primary"|"id.number.additional"|"id.msisdn"|"id.email"|"id.device"|"pii.name.full"|"pii.name.familyname"|"pii.name.givenname"|"pii.name.middlename"|"pii.gender"|"pii.address.longform"|"pii.address.street1"|"pii.address.street2"|"pii.address.postalcode"|"pii.address.town"|"pii.address.suburb"|"pii.address.region"|"pii.address.state"|"pii.address.country"|"pii.dob"|"transient.string", kvpValue?: string}
  --flags: list # Used to set additional information flags with regards to this entity and for ongoing processing.  Flags might include having the entity (not) participate in regular pep/sanctions screening Others will follow over time. — item shape: {flag?: string, value?: int}
  --gender: string@gender-completer # Used to indicate of the entity in question is: - "M"ale  - "F"emale - "U"nspecified - "O"ther (for want of a better option)  (e.g. F)
  --identityDocs: list # Collection of identity documents (photos, scans, selfies, etc) — item shape: {country: string, docScan?: list, documentId?: string, documentStatus?: "INITIALISING"|"SCAN_IN_PROGRESS"|"DOC_SCANNED"|"DOC_CHECKED", extraData?: list, idExpiry?: string, idIssued?: string, idNumber?: string, idSubType?: string, idType: "OTHER"|"DRIVERS_LICENCE"|"PASSPORT"|"VISA"|"IMMIGRATION"|"NATIONAL_ID"|"TAX_ID"|"NATIONAL_HEALTH_ID"|"CONCESSION"|"HEALTH_CONCESSION"|"PENSION"|"MILITARY_ID"|"BIRTH_CERT"|"CITIZENSHIP"|"MARRIAGE_CERT"|"DEATH_CERT"|"NAME_CHANGE"|"MOBILE_PHONE"|"UTILITY_BILL"|"BANK_STATEMENT"|"BANK_ACCOUNT"|"INTENT_PROOF"|"ATTESTATION"|"SELF_IMAGE"|"EMAIL_ADDRESS"|"MSISDN"|"DEVICE"|"VEHICLE_REGISTRATION"|"EXTERNAL_ADMIN"|"CHARGES"|"PRE_ASIC"|"ANNUAL_RETURN"|"REPORT"|"CHECK_RESULTS", region?: string}
  --name: record # shape: {displayName?: string, familyName: string, givenName?: string, honourific?: string, middleName?: string}
  --organisationData: record # Organisation details for entities. Returned from an ASIC report. — shape: {adverseCreditDataPresent?: bool, class?: record, disclosingEntityIndicator?: bool, includesNonBeneficiallyHeld?: bool, kycCustomerType?: string, lastCheckDate?: string, ownershipResolved?: bool, registeredName?: string, registration?: record, shareStructure?: list, startDate?: string, status?: record, subclass?: record, type?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "noInvalidate" $noInvalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)" $qp)
  let body = {addresses: $addresses, dateOfBirth: $dateOfBirth, entityId: $body_entityId, entityProfile: $entityProfile, entityType: $entityType, extraData: $extraData, flags: $flags, gender: $gender, identityDocs: $identityDocs, name: $name, organisationData: $organisationData} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Check Result States (Batch)
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}
# operationId: UpdateCheckClassResults
export def "entity-check UpdateCheckClassResults" [
  entityId: string
  checkId: string
  checkClass: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --checkClassIds: list
  comment: string
  --status: string@status-completer # Indicates the status of a check result as set by a user. - "UNKNOWN": The user has not decided so the actual check result applies as normal. - "TRUE_POSITIVE": The check result has been acknowledged as correct but the final effect (accept/reject) has not been decided. - "TRUE_POSITIVE_ACCEPT": The check result is correct but will be ignored. This is also known as 'whitelisting' - "TRUE_POSITIVE_REJECT": The check result is correct and will be used. - "FALSE_POSITIVE": The check result is not applicable and will be ignored. - "STALE": The check result will become invisible, will not be considered   and will not count towards due diligence requirements.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)/check/($checkId)/($checkClass)")
  let body = {checkClassIds: $checkClassIds, comment: $comment, status: $status} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Check Result State
#
# POST /entity/{entityId}/check/{checkId}/{checkClass}/{checkClassId}
# operationId: UpdateCheckClassResult
export def "entity-check UpdateCheckClassResult" [
  entityId: string
  checkId: string
  checkClass: string
  checkClassId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --status: string # Set the new status of the Check Class (PRO/BCRO). Valid values are:   - "unknown"   - "true_positive"   - "true_positive_accept"   - "true_positive_reject"   - "false_positive"   - "stale"
  --undo: oneof<nothing, bool> # Undo a prior operation.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "status" $status "scalar") (serialize-qp "undo" $undo "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/check/($checkId)/($checkClass)/($checkClassId)" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Entity Verication Check Details
#
# GET /entity/{entityId}/checks
# operationId: QueryEntityChecks
export def "entity-checks QueryEntityChecks" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --alldata: oneof<nothing, bool> # Requests that literally all data should be included in the response to a "get checks" request. This is as opposed to a filtered view where expired results are by default not included for entities that have an assigned profile.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "alldata" $alldata "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/checks" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Entity Blacklist State.
#
# POST /entity/{entityId}/flag/blacklist
# operationId: BlacklistEntity
export def "entity-flag-blacklist BlacklistEntity" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --reason: string # Set the reason for blacklisting. Valid values are:   - "NO_REASON_SUPPLIED"   - "FABRICATED_IDENTITY"   - "IDENTITY_TAKEOVER"   - "FALSIFIED_ID_DOCUMENTS"   - "STOLEN_ID_DOCUMENTS"   - "MERCHANT_FRAUD"   - "NEVER_PAY_BUST_OUT"   - "CONFLICTING_DATA_PROVIDED"   - "MONEY_MULE"   - "FALSE_FRAUD_CLAIM"   - "FRAUDULENT_3RD_PARTY"   - "COMPANY_TAKEOVER"   - "FICTITIOUS_EMPLOYER"   - "COLLUSIVE_EMPLOYER"   - "OVER_VALUATION_OF_ASSETS"   - "FALSIFIED_EMPLOYMENT_DETAILS"   - "MANIPULATED_IDENTITY"   - "SYNDICATED_FRAUD"   - "INTERNAL_FRAUD"   - "BANK_FRAUD"   - "UNDISCLOSED_DATA"   - "FALSE_HARDSHIP"   - "SMR_REPORT_LODGED"   - "2X_SMR_REPORTS_LODGED"
  --blockedBy: string # Specify who is setting the entity as blacklisted.
  --attribute: string # Specify the blacklisted attribute. Valid values are:   - "ENTIRE_PROFILE"   - "FULL_NAME"   - "EMAIL_ADDRESS"   - "PHONE_NUMBER"   - "ID_DOCUMENT"   - "MAILING_ADDRESS"   - "RESIDENTIAL_ADDRESS"   
  --originalId: string # Specify the Id of the matching blacklisted entity or single data-point.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "blockedBy" $blockedBy "scalar") (serialize-qp "attribute" $attribute "scalar") (serialize-qp "originalId" $originalId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/flag/blacklist" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Resolve Duplicate States.
#
# POST /entity/{entityId}/flag/duplicate/{otherId}
# operationId: FlagDuplicateEntity
export def "entity-flag-duplicate FlagDuplicateEntity" [
  entityId: string
  otherId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "set" $set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/flag/duplicate/($otherId)" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Entity Ongoing AML Monitoring Status.
#
# POST /entity/{entityId}/flag/monitor
# operationId: EntityMonitoring
export def "entity-flag-monitor EntityMonitoring" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "set" $set "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/flag/monitor" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Set Entity Watchlist State.
#
# POST /entity/{entityId}/flag/watchlist
# operationId: WatchlistEntity
export def "entity-flag-watchlist WatchlistEntity" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: oneof<nothing, bool> # Set the value of an entity flag.
  --reason: string # Set the reason for watchlisting. Valid values are:  - "WAS_BLACKLISTED"
  --comment: string # A comment describing the reason for a request.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "reason" $reason "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/flag/watchlist" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieve Entity Details and Document Scan Data
#
# GET /entity/{entityId}/full
# operationId: QueryEntityFull
export def "entity-full QueryEntityFull" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)/full")
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Entity and Get IDV Token
#
# POST /entity/{entityId}/idvalidate/getToken
# operationId: UpdateEntityGetIDVToken
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-idvalidate-get-token UpdateEntityGetIDVToken" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --applicantId: string # The applicantId previously supplied when creating a token for the first time for an entity. Only required if re-submitting for a fresh token on a previously created applicant.
  --applicationId: string # If this is for a native application SDK, then we need the applicationId as reported by the SDK. This will then be tied to the token so it cannot be used in another application or handset.  You must send either an applicationID or a referrer (see below)
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
  --referrer: string # If this is for a web SDK, then you need to supply the referrer domain so that the token can be validated by the IDV service  You must send either a referrer or an applicationID (see above)
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)/idvalidate/getToken")
  let body = {applicantId: $applicantId, applicationId: $applicationId, entity: $entity, referrer: $referrer} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Entity and Initiate IDV Process
#
# POST /entity/{entityId}/idvalidate/initProcess
# operationId: UpdateEntityInitIDVProcess
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-idvalidate-init-process UpdateEntityInitIDVProcess" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --deviceCheckDetails: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/entity/($entityId)/idvalidate/initProcess")
  let body = {deviceCheckDetails: $deviceCheckDetails, entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Entity States
#
# POST /entity/{entityId}/status
# operationId: UpdateEntityState
export def "entity-status UpdateEntityState" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --set: string@set-completer # The status of an entity. Valid values are:   - "wait": Waiting for new details from entity.   - "fail": Manually fail the onboarding process.   - "archived": Hide entity from on onboarding.   - "clear": Remove any of the above manual states as well as any manual risk.   - "inactive": Hide entity and prevent any further operations on it. Cannot be cleared.
  --risk: string@risk-completer # The risk override setting for an entity. This value will be used until a verify result updates a real risk factor. Valid values are:   - "low"   - "medium"   - "high"   - "unacceptable"   - "significant"
  --comment: string # A comment describing the reason for a request.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "set" $set "scalar") (serialize-qp "risk" $risk "scalar") (serialize-qp "comment" $comment "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/status" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update Entity and Push Self-Verification Link
#
# POST /entity/{entityId}/verify/pushToMobile
# operationId: UpdateCheckEntityPushToMobile
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-verify-push-to-mobile UpdateCheckEntityPushToMobile" [
  entityId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --nopush: oneof<nothing, bool> # If set to true, then no SMS/email will be pushed. It will be up to the API caller to manage the delivery of the link.
  --phase: int # Set the Push To Mobile phase.  Currently supported values: - 2
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --deviceCheckDetails: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "nopush" $nopush "scalar") (serialize-qp "phase" $phase "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/verify/pushToMobile" $qp)
  let body = {deviceCheckDetails: $deviceCheckDetails, entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Update Entity and Verify Details
#
# POST /entity/{entityId}/verify/{checkType}/{resultLevel}
# operationId: UpdateCheckEntity
# --deviceCheckDetails item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
# --entity shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
export def "entity-verify UpdateCheckEntity" [
  entityId: string
  checkType: string
  resultLevel: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --force: oneof<nothing, bool> # Force the verification to run, overriding any data aging or past check
  --noInvalidate: oneof<nothing, bool> # Disable check result invalidation for this update request.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
  --X-Frankie-Background: int # If this header parameter is supplied and set to 1, then the request will not wait for the process to finish, and will return a 202 if there are no obvious errors in the input. The request will then run in the background and send a notification back to the customer. See out callback API for details on this.  See more details here:   https://apidocs.frankiefinancial.com/docs/asynchronous-calls-backgrounding-processes
  --deviceCheckDetails: list # item shape: {activityType?: "SIGNUP"|"LOGIN"|"PAYMENT"|"CONFIRMATION"|"_<Vendor Specific List>", additionalData?: list, checkSessionKey?: string, checkType?: "DEVICE"|"BIOMETRIC"}
  entity: record # Describes all of the data being used to verify an entity. — shape: {addresses?: list, dateOfBirth?: record, entityId?: string, entityProfile?: string, entityType?: "INDIVIDUAL"|"TRUST"|"ORGANISATION", extraData?: list, flags?: list, gender?: "U"|"F"|"M"|"O", identityDocs?: list, name?: record, organisationData?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "force" $force "scalar") (serialize-qp "noInvalidate" $noInvalidate "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/entity/($entityId)/verify/($checkType)/($resultLevel)" $qp)
  let body = {deviceCheckDetails: $deviceCheckDetails, entity: $entity} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID, "X-Frankie-Background": $X_Frankie_Background} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# (Re)retrieve Response Result.
#
# GET /retrieve/response/{requestId}
# operationId: RetrieveResult
export def "retrieve-response RetrieveResult" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --payload: string@payload-completer # Specifies the type of the payload field in the retrieved response. Default is 'string'.
  --X-Frankie-CustomerID: string # Customer ID issued by Frankie Financial. This will never change. Your API key, which is mapped to this identity, will change over time.
  --X-Frankie-CustomerChildID: string # If, as a Frankie Customer, you are acting on behalf of your own customers, then you can populate this field with a Frankie-assigned ID.  Note: If using a CustomerChildID, you will also need a separate api_key for each child.  Any documents, checks, entities that are created when this field has been populated will now be tied to this CustomerID + CustomerChildID combination. Just as Customers cannot see data created by other Customers, so too a Customer's Children will not be able to see each other's data.  A Customer can see the documents/entities and checks of all their Children.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "payload" $payload "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/retrieve/response/($requestId)" $qp)
  let extra_headers = {"X-Frankie-CustomerID": $X_Frankie_CustomerID, "X-Frankie-CustomerChildID": $X_Frankie_CustomerChildID} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Service Status
#
# GET /ruok
# operationId: StatusCheck
export def "ruok StatusCheck" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --askingNicely: oneof<nothing, bool> # If set to true, the request is being made politely.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "askingNicely" $askingNicely "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/ruok" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Push Notification Payload
#
# POST /your/configured/path/{requestId}
# operationId: notifyResult
export def "your-configured-path notifyResult" [
  requestId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --checkId: string # If you're calling a processing function of some kind, a check number will be issued. This field will only be present if the function you're calling would normally return a checkId (such as scan, verify, and compare).  (format: uuid)
  --documentId: string # Only supplied if the original request was tied to a document. This will be the same ID that was sent in the original acceptance.  (format: uuid)
  --entityCustomerReference: string # If the entity in entityId above has had an external service ID attached to it in the entity extraData with kvpKey = customer_reference, then this is that kvpValue  (e.g. AU0123456)
  --entityId: string # Only supplied if the original request was tied to an entity. This will be the same ID that was sent in the original acceptance.  (format: uuid)
  --function: string # Short description of the original function called, or function that was triggered.  (e.g. entity.create)
  --functionResult: string@functionResult-completer # High level indication of the final disposition of a backgrounded function - "COMPLETED": the request completed (not that the final result is a success, just that we completed) - "FAILED": the request failed.  - "INCOMPLETE": could not complete the request.  (e.g. COMPLETED)
  --linkReference: string # URI for resource containing more details about the reason for the notification.  (format: uri, e.g. https://portal.frankiefinancial.io/entity/3fa85f64-5717-4562-b3fc-2c963f66afa6)
  --message: string # A brief, human readable message describing the reason for the notification.  (e.g. Entity successfully created)
  --notificationType: string@notificationType-completer # Indicates the type of notification being pushed. - "FUNCTION": A request that you previously backgrounded has completed and this is the notification that is it complete (success is another matter) - "RESULT": Like the FUNCTION notification, this tells you that a previously backgrounded request has completed, and that there is a set of results in the payload pointer. - "EVENT": There has been a stateful change in a document, entity or some other piece of data that we are holding/monitoring for you. This is an indication that you may wish to take some action. - "ALERT": Like the EVENT, except that the severity of the notification indicates that action is almost certainly required.
  --body-requestId: string # Unique identifier for every request. Can be used for tracking down answers with technical support.   Uses the ULID format (a time-based, sortable UUID)  Note: this will be different for every request.  (format: ulid, e.g. 01BFJA617JMJXEW6G7TDDXNSHX)
  --username: string # The portal username that initiated the operation that led to this notification. If applicable and available.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "api_key"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/your/configured/path/($requestId)")
  let body = {checkId: $checkId, documentId: $documentId, entityCustomerReference: $entityCustomerReference, entityId: $entityId, function: $function, functionResult: $functionResult, linkReference: $linkReference, message: $message, notificationType: $notificationType, requestId: $body_requestId, username: $username} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
