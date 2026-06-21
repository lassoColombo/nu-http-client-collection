# Auto-generated client for Legal Entity Management API v3
# Source: https://api.apis.guru/v2/specs/adyen.com/LegalEntityService/3/openapi.json
# Auth: --token flag or $env.LEGAL_ENTITY_MANAGEMENT_API_TOKEN

const BASE_URL = "https://kyc-test.adyen.com/lem/v3"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o LEGAL_ENTITY_MANAGEMENT_API_TOKEN | default "" }
  let scheme = ($auth_scheme | default "bearer")
  if ($scheme == "none") or ($token_val | is-empty) { return {scheme: $scheme, headers: {}, query: "", location: "none"} }
  match $scheme {
    "x-api-key" => { {scheme: $scheme, headers: {X-API-Key: $token_val}, query: "", location: "header"} }
    "basic" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val)"}, query: "", location: "header"} }
    "basic-credentials" => { {scheme: $scheme, headers: {Authorization: $"Basic ($token_val | encode base64)"}, query: "", location: "header"} }
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

def base-url-completer [] { ["https://kyc-test.adyen.com/lem/v3"] }
def auth-scheme-completer [] { ["x-api-key" "basic" "basic-credentials"] }

# Completers for enum parameters
def service-completer [] { ["banking" "issuing" "paymentProcessing"] }
def type-completer [] { ["bankStatement" "constitutionalDocument" "driversLicense" "identityCard" "nationalIdNumber" "passport" "proofOfAddress" "proofOfIndustry" "proofOfNationalIdNumber" "proofOfOrganizationTaxInfo" "proofOfResidency" "registrationDocument" "vatDocument"] }
def type-completer-1 [] { ["individual" "organization" "soleProprietorship" "trust" "unincorporatedPartnership"] }
def type-completer-2 [] { ["adyenAccount" "adyenCapital" "adyenCard" "adyenForPlatformsAdvanced" "adyenForPlatformsManage" "adyenFranchisee" "adyenIssuing"] }
def type-completer-3 [] { ["bankAccount" "recurringDetail"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "business-lines create" } } | get name | first)
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
export def "business-lines create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  industry_code: string # A code that represents the industry of the legal entity. For example, **4431A** for computer software stores.
  legal_entity_id: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --sales-channels: list<string> # A list of channels where goods or services are sold. Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**. Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line. Possible values:**paymentProcessing**, **issuing**, **banking**
  --source-of-funds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --web-data: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --web-data-exemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/businessLines")
  let req_body = {"capability": $capability, "industryCode": $industry_code, "legalEntityId": $legal_entity_id, "salesChannels": $sales_channels, "service": $service, "sourceOfFunds": $source_of_funds, "webData": $web_data, "webDataExemption": $web_data_exemption} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a business line
#
# DELETE /businessLines/{id}
# operationId: delete-businessLines-id
export def "business-lines delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/businessLines/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a business line
#
# GET /businessLines/{id}
# operationId: get-businessLines-id
export def "business-lines get" [
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
]: nothing -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/businessLines/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a business line
#
# PATCH /businessLines/{id}
# operationId: patch-businessLines-id
# --sourceOfFunds shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
# --webData item shape: {webAddress?: string}
# --webDataExemption shape: {reason?: "noOnlinePresence"}
@deprecated --flag capability
export def "business-lines update" [
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
  --capability: string # The capability for which you are creating the business line. For example, **receivePayments**. (DEPRECATED)
  --industry-code: string # A code that represents the industry of your legal entity. For example, **4431A** for computer software stores.
  --legal-entity-id: string # Unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) that owns the business line.
  --sales-channels: list<string> # A list of channels where goods or services are sold. Possible values: **pos**, **posMoto**, **eCommerce**, **ecomMoto**, **payByLink**. Required only in combination with the `service` **paymentProcessing**.
  service: string@service-completer # The service for which you are creating the business line. Possible values:**paymentProcessing**, **issuing**, **banking**
  --source-of-funds: record # shape: {acquiringBusinessLineId?: string, adyenProcessedFunds?: bool, description?: string, type?: "business"}
  --web-data: list # List of website URLs where your user's goods or services are sold. When this is required for a service but your user does not have an online presence, provide the reason in the `webDataExemption` object. — item shape: {webAddress?: string}
  --web-data-exemption: record # shape: {reason?: "noOnlinePresence"}
]: any -> record<capability: string, id: string, industryCode: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, salesChannels: list<string>, service: string, sourceOfFunds: record<acquiringBusinessLineId: string, adyenProcessedFunds: bool, description: string, type: string>, webData: table<webAddress: string, webAddressId: string>, webDataExemption: record<reason: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/businessLines/{id}"))
  let req_body = {"capability": $capability, "industryCode": $industry_code, "legalEntityId": $legal_entity_id, "salesChannels": $sales_channels, "service": $service, "sourceOfFunds": $source_of_funds, "webData": $web_data, "webDataExemption": $web_data_exemption} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Upload a document for verification checks
#
# POST /documents
# operationId: post-documents
# --attachment shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --attachments item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --owner shape: {id: string, type: string}
@deprecated --flag expiry-date
@deprecated --flag issuer-country
@deprecated --flag issuer-state
export def "documents create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiry-date: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --file-name: string # The filename of the document.
  --issuer-country: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuer-state: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type. When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**. When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**. When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**. * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**. * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**. * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/documents")
  let req_body = {"attachment": $attachment, "attachments": $attachments, "description": $description, "expiryDate": $expiry_date, "fileName": $file_name, "issuerCountry": $issuer_country, "issuerState": $issuer_state, "number": $number, "owner": $owner, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a document
#
# DELETE /documents/{id}
# operationId: delete-documents-id
export def "documents delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a document
#
# GET /documents/{id}
# operationId: get-documents-id
export def "documents get" [
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
]: nothing -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a document
#
# PATCH /documents/{id}
# operationId: patch-documents-id
# --attachment shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --attachments item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
# --owner shape: {id: string, type: string}
@deprecated --flag expiry-date
@deprecated --flag issuer-country
@deprecated --flag issuer-state
export def "documents update" [
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
  --attachment: record # shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  attachments: list # Array that contains the document. The array supports multiple attachments for uploading different sides or pages of a document. — item shape: {content: string, contentType?: string, filename?: string, pageName?: string, pageType?: string}
  description: string # Your description for the document.
  --expiry-date: string # The expiry date of the document, in YYYY-MM-DD format. (DEPRECATED)
  --file-name: string # The filename of the document.
  --issuer-country: string # The two-character [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country code where the document was issued. For example, **US**. (DEPRECATED)
  --issuer-state: string # The state or province where the document was issued (AU only). (DEPRECATED)
  --number: string # The number in the document.
  owner: record # shape: {id: string, type: string}
  type: string@type-completer # Type of document, used when providing an ID number or uploading a document. The possible values depend on the legal entity type. When providing ID numbers: * For **individual**, the `type` values can be **driversLicense**, **identityCard**, **nationalIdNumber**, or **passport**. When uploading photo IDs: * For **individual**, the `type` values can be **identityCard**, **driversLicense**, or **passport**. When uploading other documents: * For **organization**, the `type` values can be **proofOfAddress**, **registrationDocument**, **vatDocument**, **proofOfOrganizationTaxInfo**, **proofOfOwnership**, or **proofOfIndustry**. * For **individual**, the `type` values can be **identityCard**, **driversLicense**, **passport**, **proofOfNationalIdNumber**, **proofOfResidency**, **proofOfIndustry**, or **proofOfIndividualTaxId**. * For **soleProprietorship**, the `type` values can be **constitutionalDocument**, **proofOfAddress**, or **proofOfIndustry**. * Use **bankStatement** to upload documents for a [transfer instrument](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/transferInstruments__resParam_id).
]: any -> record<attachment: record<content: string, contentType: string, filename: string, pageName: string, pageType: string>, attachments: table<content: string, contentType: string, filename: string, pageName: string, pageType: string>, creationDate: string, description: string, expiryDate: string, fileName: string, id: string, issuerCountry: string, issuerState: string, modificationDate: string, number: string, owner: record<id: string, type: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/documents/{id}"))
  let req_body = {"attachment": $attachment, "attachments": $attachments, "description": $description, "expiryDate": $expiry_date, "fileName": $file_name, "issuerCountry": $issuer_country, "issuerState": $issuer_state, "number": $number, "owner": $owner, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Create a legal entity
#
# POST /legalEntities
# operationId: post-legalEntities
# --entityAssociations item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
# --individual shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
# --organization shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
# --soleProprietorship shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
export def "legal-entities create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --entity-associations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --sole-proprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  type: string@type-completer-1 # The type of legal entity. Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/legalEntities")
  let req_body = {"entityAssociations": $entity_associations, "individual": $individual, "organization": $organization, "reference": $reference, "soleProprietorship": $sole_proprietorship, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get a legal entity
#
# GET /legalEntities/{id}
# operationId: get-legalEntities-id
export def "legal-entities get" [
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
]: nothing -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a legal entity
#
# PATCH /legalEntities/{id}
# operationId: patch-legalEntities-id
# --entityAssociations item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
# --individual shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
# --organization shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
# --soleProprietorship shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
export def "legal-entities update" [
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
  --entity-associations: list # List of legal entities associated with the current legal entity. For example, ultimate beneficial owners associated with an organization through ownership or control, or as signatories. — item shape: {jobTitle?: string, legalEntityId: string, type: "pciSignatory"|"signatory"|"soleProprietorship"|"uboThroughControl"|"uboThroughOwnership"|"ultimateParentCompany"}
  --individual: record # shape: {birthData?: record, email?: string, identificationData?: record, name: record, nationality?: string, phone?: record, residentialAddress: record, taxInformation?: list, webData?: record}
  --organization: record # shape: {dateOfIncorporation?: string, description?: string, doingBusinessAs?: string, email?: string, legalName: string, phone?: record, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, stockData?: record, taxInformation?: list, taxReportingClassification?: record, type?: "associationIncorporated"|"governmentalOrganization"|"listedPublicCompany"|"nonProfit"|"partnershipIncorporated"|"privateCompany", vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", ... (2 more fields)}
  --reference: string # Your reference for the legal entity, maximum 150 characters.
  --sole-proprietorship: record # shape: {countryOfGoverningLaw: string, dateOfIncorporation?: string, doingBusinessAs?: string, name: string, principalPlaceOfBusiness?: record, registeredAddress: record, registrationNumber?: string, vatAbsenceReason?: "industryExemption"|"belowTaxThreshold", vatNumber?: string}
  --type: string@type-completer-1 # The type of legal entity. Possible values: **individual**, **organization**, or **soleProprietorship**.
]: any -> record<capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, documents: table<id: string>, entityAssociations: table<associatorId: string, entityType: string, jobTitle: string, legalEntityId: string, name: string, type: string>, id: string, individual: record<birthData: record<dateOfBirth: string>, email: string, identificationData: record<cardNumber: string, expiryDate: string, issuerCountry: string, issuerState: string, nationalIdExempt: bool, number: string, type: string>, name: record<firstName: string, infix: string, lastName: string>, nationality: string, phone: record<number: string, type: string>, residentialAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, taxInformation: list<record>, webData: record<webAddress: string, webAddressId: string>>, organization: record<dateOfIncorporation: string, description: string, doingBusinessAs: string, email: string, legalName: string, phone: record<number: string, type: string>, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, stockData: record<marketIdentifier: string, stockNumber: string, tickerSymbol: string>, taxInformation: list<record>, taxReportingClassification: record<businessType: string, financialInstitutionNumber: string, mainSourceOfIncome: string, type: string>, type: string, vatAbsenceReason: string, vatNumber: string, webData: record<webAddress: string, webAddressId: string>>, problems: table<entity: record, verificationErrors: list>, reference: string, soleProprietorship: record<countryOfGoverningLaw: string, dateOfIncorporation: string, doingBusinessAs: string, name: string, principalPlaceOfBusiness: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registeredAddress: record<city: string, country: string, postalCode: string, stateOrProvince: string, street: string, street2: string>, registrationNumber: string, vatAbsenceReason: string, vatNumber: string>, transferInstruments: table<accountIdentifier: string, id: string, realLastFour: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}"))
  let req_body = {"entityAssociations": $entity_associations, "individual": $individual, "organization": $organization, "reference": $reference, "soleProprietorship": $sole_proprietorship, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get all business lines under a legal entity
#
# GET /legalEntities/{id}/businessLines
# operationId: get-legalEntities-id-businessLines
export def "legal-entities-business-lines get" [
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
]: nothing -> record<businessLines: table<capability: string, id: string, industryCode: string, legalEntityId: string, problems: list, salesChannels: list, service: string, sourceOfFunds: record, webData: list, webDataExemption: record>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/businessLines"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Check a legal entity's verification errors
#
# POST /legalEntities/{id}/checkVerificationErrors
# operationId: post-legalEntities-id-checkVerificationErrors
export def "legal-entities-check-verification-errors create" [
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
]: nothing -> record<problems: table<entity: record, verificationErrors: list>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/checkVerificationErrors"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a link to an Adyen-hosted onboarding page
#
# POST /legalEntities/{id}/onboardingLinks
# operationId: post-legalEntities-id-onboardingLinks
export def "legal-entities-onboarding-links create" [
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
  --locale: string # The language that will be used for the page, specified by a combination of two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language and [ISO 3166-1 alpha-2](https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2) country codes. See [possible values](https://docs.adyen.com/marketplaces-and-platforms/collect-verification-details/hosted#supported-languages). If not specified in the request or if the language is not supported, the page uses the browser language. If the browser language is not supported, the page uses **en-US** by default.
  --redirect-url: string # The URL where the user is redirected after they complete hosted onboarding.
  --settings: record # Boolean key-value pairs indicating the settings for the hosted onboarding page. The keys are the settings. By default, the values are set to **true**. Set to **false** to not allow the action. Possible keys: - **changeLegalEntityType**: The user can change their legal entity type. - **editPrefilledCountry**: The user can change the country of their legal entity's address, for example the registered address of an organization.
  --theme-id: string # The unique identifier of the hosted onboarding theme.
]: any -> record<url: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/onboardingLinks"))
  let req_body = {"locale": $locale, "redirectUrl": $redirect_url, "settings": $settings, "themeId": $theme_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get PCI questionnaire details
#
# GET /legalEntities/{id}/pciQuestionnaires
# operationId: get-legalEntities-id-pciQuestionnaires
export def "legal-entities-pci-questionnaires list" [
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
]: nothing -> record<data: table<createdAt: string, id: string, validUntil: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/pciQuestionnaires"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Generate PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/generatePciTemplates
# operationId: post-legalEntities-id-pciQuestionnaires-generatePciTemplates
export def "legal-entities-pci-questionnaires-generate-pci-templates create" [
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
  --language: string # Sets the language of the PCI questionnaire. Its value is a two-character [ISO 639-1](https://en.wikipedia.org/wiki/ISO_639-1) language code, for example, **en**.
]: any -> record<content: string, language: string, pciTemplateReferences: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/pciQuestionnaires/generatePciTemplates"))
  let req_body = {"language": $language} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Sign PCI questionnaire
#
# POST /legalEntities/{id}/pciQuestionnaires/signPciTemplates
# operationId: post-legalEntities-id-pciQuestionnaires-signPciTemplates
export def "legal-entities-pci-questionnaires-sign-pci-templates create" [
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
  pci_template_references: list<string> # The array of Adyen-generated unique identifiers for the questionnaires.
  signed_by: string # The [legal entity ID](https://docs.adyen.com/api-explorer/#/legalentity/latest/post/legalEntities__resParam_id) of the individual who signs the PCI questionnaire.
]: any -> record<pciQuestionnaireIds: list<string>, signedBy: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/pciQuestionnaires/signPciTemplates"))
  let req_body = {"pciTemplateReferences": $pci_template_references, "signedBy": $signed_by} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get PCI questionnaire
#
# GET /legalEntities/{id}/pciQuestionnaires/{pciid}
# operationId: get-legalEntities-id-pciQuestionnaires-pciid
export def "legal-entities-pci-questionnaires get" [
  id: string
  pciid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<content: string, createdAt: string, id: string, validUntil: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($pciid | is-empty) { error make --unspanned { msg: "path parameter 'pciid' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), pciid: (encode-path-segment $pciid)} | format pattern "/legalEntities/{id}/pciQuestionnaires/{pciid}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get Terms of Service document
#
# POST /legalEntities/{id}/termsOfService
# operationId: post-legalEntities-id-termsOfService
export def "legal-entities-terms-of-service create" [
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
  --language: string # The language to be used for the Terms of Service document, specified by the two letter [ISO 639-1](https://en.wikipedia.org/wiki/List_of_ISO_639-1_codes) language code. For example, **nl** for Dutch.
  --type: string@type-completer-2 # The type of Terms of Service.
]: any -> record<document: string, id: string, language: string, termsOfServiceDocumentId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/termsOfService"))
  let req_body = {"language": $language, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Accept Terms of Service
#
# PATCH /legalEntities/{id}/termsOfService/{termsofservicedocumentid}
# operationId: patch-legalEntities-id-termsOfService-termsofservicedocumentid
export def "legal-entities-terms-of-service update" [
  id: string
  termsofservicedocumentid: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --accepted-by: string # The unique identifier of the user accepting the Terms of Service.
  --ip-address: string # The IP address of the user accepting the Terms of Service.
]: any -> record<acceptedBy: string, id: string, ipAddress: string, language: string, termsOfServiceDocumentId: string, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  if ($termsofservicedocumentid | is-empty) { error make --unspanned { msg: "path parameter 'termsofservicedocumentid' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id), termsofservicedocumentid: (encode-path-segment $termsofservicedocumentid)} | format pattern "/legalEntities/{id}/termsOfService/{termsofservicedocumentid}"))
  let req_body = {"acceptedBy": $accepted_by, "ipAddress": $ip_address} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Get Terms of Service information for a legal entity
#
# GET /legalEntities/{id}/termsOfServiceAcceptanceInfos
# operationId: get-legalEntities-id-termsOfServiceAcceptanceInfos
export def "legal-entities-terms-of-service-acceptance-infos get" [
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
]: nothing -> record<data: table<acceptedBy: string, acceptedFor: string, createdAt: string, id: string, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/legalEntities/{id}/termsOfServiceAcceptanceInfos"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a list of hosted onboarding page themes
#
# GET /themes
# operationId: get-themes
export def "themes list" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
]: nothing -> record<next: string, previous: string, themes: table<createdAt: string, description: string, id: string, properties: record, updatedAt: string>> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/themes")
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get an onboarding link theme
#
# GET /themes/{id}
# operationId: get-themes-id
export def "themes get" [
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
]: nothing -> record<createdAt: string, description: string, id: string, properties: record, updatedAt: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/themes/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Create a transfer instrument
#
# POST /transferInstruments
# operationId: post-transferInstruments
# --bankAccount shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
export def "transfer-instruments create" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  bank_account: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument. Possible value: **bankAccount**.
]: any -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  let full_url = (build-url $base "/transferInstruments")
  let req_body = {"bankAccount": $bank_account, "legalEntityId": $legal_entity_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}

# Delete a transfer instrument
#
# DELETE /transferInstruments/{id}
# operationId: delete-transferInstruments-id
export def "transfer-instruments delete" [
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
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transferInstruments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Get a transfer instrument
#
# GET /transferInstruments/{id}
# operationId: get-transferInstruments-id
export def "transfer-instruments get" [
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
]: nothing -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transferInstruments/{id}"))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: {}, body: null}
}

# Update a transfer instrument
#
# PATCH /transferInstruments/{id}
# operationId: patch-transferInstruments-id
# --bankAccount shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
export def "transfer-instruments update" [
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
  bank_account: record # shape: {accountIdentification?: any, accountType?: string, countryCode?: string}
  legal_entity_id: string # The unique identifier of the [legal entity](https://docs.adyen.com/api-explorer/legalentity/latest/post/legalEntities#responses-200-id) that owns the transfer instrument.
  type: string@type-completer-3 # The type of transfer instrument. Possible value: **bankAccount**.
]: any -> record<bankAccount: record<accountIdentification: any, accountType: string, countryCode: string>, capabilities: record, documentDetails: table<active: bool, description: string, fileName: string, id: string, modificationDate: string, type: string>, id: string, legalEntityId: string, problems: table<entity: record, verificationErrors: list>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "basic"))
  let base = ($base_url | default $BASE_URL)
  if ($id | is-empty) { error make --unspanned { msg: "path parameter 'id' must be non-empty" } }
  let full_url = (build-url $base ({id: (encode-path-segment $id)} | format pattern "/transferInstruments/{id}"))
  let req_body = {"bankAccount": $bank_account, "legalEntityId": $legal_entity_id, "type": $type} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: {}, body: $req_body}
}
