# Auto-generated client for Legal Entity Management API v3
# Source: https://api.apis.guru/v2/specs/adyen.com/LegalEntityService/3/openapi.json
# Auth: --token flag or $env.LEGAL_ENTITY_MANAGEMENT_API_TOKEN

const BASE_URL = "https://kyc-test.adyen.com/lem/v3"
const DEFAULT_AUTH = "x-api-key"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LEGAL_ENTITY_MANAGEMENT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {headers: {}, query: ""} }
  match $scheme {
    "x-api-key" => { {headers: {X-API-Key: $token_val}, query: ""} }
    "basic" => { {headers: {Authorization: $"Basic ($token_val)"}, query: ""} }
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

def base-url-completer [] { ["https://kyc-test.adyen.com/lem/v3"] }
def auth-scheme-completer [] { ["x-api-key" "basic"] }

# Completers for enum parameters
def service-completer [] { ["banking" "issuing" "paymentProcessing"] }
def type-completer [] { ["bankStatement" "constitutionalDocument" "driversLicense" "identityCard" "nationalIdNumber" "passport" "proofOfAddress" "proofOfIndustry" "proofOfNationalIdNumber" "proofOfOrganizationTaxInfo" "proofOfResidency" "registrationDocument" "vatDocument"] }
def type-completer-1 [] { ["individual" "organization" "soleProprietorship" "trust" "unincorporatedPartnership"] }
def type-completer-2 [] { ["adyenAccount" "adyenCapital" "adyenCard" "adyenForPlatformsAdvanced" "adyenForPlatformsManage" "adyenFranchisee" "adyenIssuing"] }
def type-completer-3 [] { ["bankAccount" "recurringDetail"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-lines post-businessLines" } } | get name | first)
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

# Create a business line
#
# POST /businessLines
# operationId: post-businessLines
# --sourceOfFunds shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
# --webData item shape: {webAddress?: string}
# --webDataExemption shape: {reason?: "noOnlinePresence"}
@deprecated --flag capability
export def "business-lines post-businessLines" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  industryCode: string # A code that represents the industry of the legal entity. For example, **4431A** for computer software stores.
  legalEntityId: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --salesChannels: list # A list of channels where goods or services are sold.  Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**.  Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line.  Possible values:**paymentProcessing**, **issuing**, **banking**
  --sourceOfFunds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --webData: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --webDataExemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/businessLines")
  let body = {capability: $capability, industryCode: $industryCode, legalEntityId: $legalEntityId, salesChannels: $salesChannels, service: $service, sourceOfFunds: $sourceOfFunds, webData: $webData, webDataExemption: $webDataExemption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a business line
#
# DELETE /businessLines/{id}
# operationId: delete-businessLines-id
export def "business-lines delete-businessLines-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businessLines/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a business line
#
# GET /businessLines/{id}
# operationId: get-businessLines-id
export def "business-lines get-businessLines-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businessLines/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a business line
#
# PATCH /businessLines/{id}
# operationId: patch-businessLines-id
# --sourceOfFunds shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
# --webData item shape: {webAddress?: string}
# --webDataExemption shape: {reason?: "noOnlinePresence"}
@deprecated --flag capability
export def "business-lines patch-businessLines-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  --industryCode: string # A code that represents the industry of your legal entity. For example, **4431A** for computer software stores.
  --legalEntityId: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --salesChannels: list # A list of channels where goods or services are sold.  Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**.  Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line.  Possible values:**paymentProcessing**, **issuing**, **banking**
  --sourceOfFunds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --webData: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --webDataExemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/businessLines/($id)")
  let body = {capability: $capability, industryCode: $industryCode, legalEntityId: $legalEntityId, salesChannels: $salesChannels, service: $service, sourceOfFunds: $sourceOfFunds, webData: $webData, webDataExemption: $webDataExemption} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Upload a document for verification checks
#
# POST /documents
# operationId: post-documents
# --attachment shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --attachments item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --owner shape: {id: string, type: string}
@deprecated --flag expiryDate
@deprecated --flag issuerCountry
@deprecated --flag issuerState
export def "documents post-documents" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiryDate: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --fileName: string # The filename of the document.
  --issuerCountry: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuerState: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type.  When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**.  When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**.  When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**.   * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**.  * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**.  * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let body = {attachment: $attachment, attachments: $attachments, description: $description, expiryDate: $expiryDate, fileName: $fileName, issuerCountry: $issuerCountry, issuerState: $issuerState, number: $number, owner: $owner, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a document
#
# DELETE /documents/{id}
# operationId: delete-documents-id
export def "documents delete-documents-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a document
#
# GET /documents/{id}
# operationId: get-documents-id
export def "documents get-documents-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a document
#
# PATCH /documents/{id}
# operationId: patch-documents-id
# --attachment shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --attachments item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --owner shape: {id: string, type: string}
@deprecated --flag expiryDate
@deprecated --flag issuerCountry
@deprecated --flag issuerState
export def "documents patch-documents-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiryDate: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --fileName: string # The filename of the document.
  --issuerCountry: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuerState: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type.  When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**.  When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**.  When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**.   * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**.  * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**.  * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/documents/($id)")
  let body = {attachment: $attachment, attachments: $attachments, description: $description, expiryDate: $expiryDate, fileName: $fileName, issuerCountry: $issuerCountry, issuerState: $issuerState, number: $number, owner: $owner, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create a legal entity
#
# POST /legalEntities
# operationId: post-legalEntities
# --entityAssociations item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
# --individual shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
# --organization shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string, webData?: record}
# --soleProprietorship shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
export def "legal-entities post-legalEntities" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entityAssociations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string, webData?: record}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --soleProprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  type: string@type-completer-1 # The type of legal entity.   Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legalEntities")
  let body = {entityAssociations: $entityAssociations, individual: $individual, organization: $organization, reference: $reference, soleProprietorship: $soleProprietorship, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a legal entity
#
# GET /legalEntities/{id}
# operationId: get-legalEntities-id
export def "legal-entities get-legalEntities-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a legal entity
#
# PATCH /legalEntities/{id}
# operationId: patch-legalEntities-id
# --entityAssociations item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
# --individual shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
# --organization shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string, webData?: record}
# --soleProprietorship shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
export def "legal-entities patch-legalEntities-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --entityAssociations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string, webData?: record}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --soleProprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  --type: string@type-completer-1 # The type of legal entity.   Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)")
  let body = {entityAssociations: $entityAssociations, individual: $individual, organization: $organization, reference: $reference, soleProprietorship: $soleProprietorship, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get all business lines under a legal entity
#
# GET /legalEntities/{id}/businessLines
# operationId: get-legalEntities-id-businessLines
export def "legal-entities-business-lines get-legalEntities-id-businessLines" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<businessLines: table<capability: string, id: string, industryCode: string, legalEntityId: string, problems: list, salesChannels: list, service: string, sourceOfFunds: record, webData: list, webDataExemption: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/businessLines")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Check a legal entity's verification errors
#
# POST /legalEntities/{id}/checkVerificationErrors
# operationId: post-legalEntities-id-checkVerificationErrors
export def "legal-entities-check-verification-errors post-legalEntities-id-checkVerificationErrors" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<problems: table<entity: record, verificationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/checkVerificationErrors")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a link to an Adyen-hosted onboarding page
#
# POST /legalEntities/{id}/onboardingLinks
# operationId: post-legalEntities-id-onboardingLinks
export def "legal-entities-onboarding-links post-legalEntities-id-onboardingLinks" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --locale: string # The language that will be used for the page, specified by a combination of two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language and [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes. See [possible values](https://docs.adyen.com/marketplaces-and-platforms/collect-verification-details/hosted#supported-languages).   If not specified in the request or if the language is not supported, the page uses the browser language. If the browser language is not supported, the page uses **en-US** by default.
  --redirectUrl: string # The URL where the user is redirected after they complete hosted onboarding.
  --settings: record # Boolean key-value pairs indicating the settings for the hosted onboarding page. The keys are the settings. By default, the values are set to **true**. Set to **false** to not allow the action.  Possible keys:  - **changeLegalEntityType**: The user can change their legal entity type.  - **editPrefilledCountry**: The user can change the country of their legal entity's address, for example the registered address of an organization. 
  --themeId: string # The unique identifier of the hosted onboarding theme.
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/onboardingLinks")
  let body = {locale: $locale, redirectUrl: $redirectUrl, settings: $settings, themeId: $themeId} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get PCI questionnaire details
#
# GET /legalEntities/{id}/pciQuestionnaires
# operationId: get-legalEntities-id-pciQuestionnaires
export def "legal-entities-pci-questionnaires get-legalEntities-id-pciQuestionnaires" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<createdAt: string, id: string, validUntil: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/pciQuestionnaires")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Generate PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/generatePciTemplates
# operationId: post-legalEntities-id-pciQuestionnaires-generatePciTemplates
export def "legal-entities-pci-questionnaires-generate-pci-templates post-legalEntities-id-pciQuestionnaires-generatePciTemplates" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # Sets the language of the PCI questionnaire. Its value is a two-character [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1) language code, for example, **en**.
]: any -> record<content: string, language: string, pciTemplateReferences: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/pciQuestionnaires/generatePciTemplates")
  let body = {language: $language} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Sign PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/signPciTemplates
# operationId: post-legalEntities-id-pciQuestionnaires-signPciTemplates
export def "legal-entities-pci-questionnaires-sign-pci-templates post-legalEntities-id-pciQuestionnaires-signPciTemplates" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  pciTemplateReferences: list # The array of Adyen-generated unique identifiers for the questionnaires.
  signedBy: string # The [legal entity ID](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) of the individual who signs the PCI questionnaire.
]: any -> record<pciQuestionnaireIds: list<string>, signedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/pciQuestionnaires/signPciTemplates")
  let body = {pciTemplateReferences: $pciTemplateReferences, signedBy: $signedBy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get PCI questionnaire
#
# GET /legalEntities/{id}/pciQuestionnaires/{pciid}
# operationId: get-legalEntities-id-pciQuestionnaires-pciid
export def "legal-entities-pci-questionnaires get-legalEntities-id-pciQuestionnaires-pciid" [
  id: string
  pciid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, createdAt: string, id: string, validUntil: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/pciQuestionnaires/($pciid)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Terms of Service document
#
# POST /legalEntities/{id}/termsOfService
# operationId: post-legalEntities-id-termsOfService
export def "legal-entities-terms-of-service post-legalEntities-id-termsOfService" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --language: string # The language to be used for the Terms of Service document, specified by the two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code. For example, **nl** for Dutch.
  --type: string@type-completer-2 # The type of Terms of Service.
]: any -> record<document: string, id: string, language: string, termsOfServiceDocumentId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/termsOfService")
  let body = {language: $language, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Accept Terms of Service
#
# PATCH /legalEntities/{id}/termsOfService/{termsofservicedocumentid}
# operationId: patch-legalEntities-id-termsOfService-termsofservicedocumentid
export def "legal-entities-terms-of-service patch-legalEntities-id-termsOfService-termsofservicedocumentid" [
  id: string
  termsofservicedocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --acceptedBy: string # The unique identifier of the user accepting the Terms of Service.
  --ipAddress: string # The IP address of the user accepting the Terms of Service.
]: any -> record<acceptedBy: string, id: string, ipAddress: string, language: string, termsOfServiceDocumentId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/termsOfService/($termsofservicedocumentid)")
  let body = {acceptedBy: $acceptedBy, ipAddress: $ipAddress} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get Terms of Service information for a legal entity
#
# GET /legalEntities/{id}/termsOfServiceAcceptanceInfos
# operationId: get-legalEntities-id-termsOfServiceAcceptanceInfos
export def "legal-entities-terms-of-service-acceptance-infos get-legalEntities-id-termsOfServiceAcceptanceInfos" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<data: table<acceptedBy: string, acceptedFor: string, createdAt: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/legalEntities/($id)/termsOfServiceAcceptanceInfos")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a list of hosted onboarding page themes
#
# GET /themes
# operationId: get-themes
export def "themes get-themes" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, previous: string, themes: table<createdAt: string, description: string, id: string, properties: record, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/themes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get an onboarding link theme
#
# GET /themes/{id}
# operationId: get-themes-id
export def "themes get-themes-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<createdAt: string, description: string, id: string, properties: record, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/themes/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create a transfer instrument
#
# POST /transferInstruments
# operationId: post-transferInstruments
# --bankAccount shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
export def "transfer-instruments post-transferInstruments" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bankAccount: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legalEntityId: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument.  Possible value: **bankAccount**.
]: any -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transferInstruments")
  let body = {bankAccount: $bankAccount, legalEntityId: $legalEntityId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete a transfer instrument
#
# DELETE /transferInstruments/{id}
# operationId: delete-transferInstruments-id
export def "transfer-instruments delete-transferInstruments-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferInstruments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a transfer instrument
#
# GET /transferInstruments/{id}
# operationId: get-transferInstruments-id
export def "transfer-instruments get-transferInstruments-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferInstruments/($id)")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update a transfer instrument
#
# PATCH /transferInstruments/{id}
# operationId: patch-transferInstruments-id
# --bankAccount shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
export def "transfer-instruments patch-transferInstruments-id" [
  id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  bankAccount: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legalEntityId: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument.  Possible value: **bankAccount**.
]: any -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base $"/transferInstruments/($id)")
  let body = {bankAccount: $bankAccount, legalEntityId: $legalEntityId, type: $type} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
