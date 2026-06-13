# Auto-generated client for DataBoxManagementClient v2019-09-01
# Source: https://api.apis.guru/v2/specs/azure.com/databox/2019-09-01/swagger.json
# Auth: --token flag or $env.DATABOXMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o DATABOXMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def transferType-completer [] { ["ImportToAzure"] }
def deviceType-completer [] { ["DataBox" "DataBoxDisk" "DataBoxHeavy"] }
def validationType-completer [] { ["ValidateAddress" "ValidateCreateOrderLimit" "ValidateDataDestinationDetails" "ValidatePreferences" "ValidateSkuAvailability" "ValidateSubscriptionIsAllowedToCreateJob"] }
def validationCategory-completer [] { ["JobCreationValidation"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-data-box-operations List" } } | get name | first)
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

# This method gets all the operations.
#
# GET /providers/Microsoft.DataBox/operations
# operationId: Operations_List
export def "providers-microsoft-data-box-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.DataBox/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the jobs available under the subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.DataBox/jobs
# operationId: Jobs_List
export def "subscriptions-providers-microsoft-data-box-jobs List" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  --skipToken: string # $skipToken is supported on Get list of jobs, which provides the next page in the list of jobs.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataBox/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method provides the list of available skus for the given subscription and location.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataBox/locations/{location}/availableSkus
# operationId: Service_ListAvailableSkus
export def "subscriptions-providers-microsoft-data-box-locations-available-skus ListAvailableSkus" [
  subscriptionId: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  country: string # ISO country code. Country for hardware shipment. For codes check: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
  --body-location: string # Location for data transfer. For locations check: https://management.azure.com/subscriptions/SUBSCRIPTIONID/locations?api-version=2018-01-01
  --skuNames: list # Sku Names to filter for available skus
  transferType: string@transferType-completer # Type of the transfer.
]: any -> record<nextLink: string, value: table<enabled: bool, properties: record, sku: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataBox/locations/($location)/availableSkus" $qp)
  let body = {country: $country, location: $body_location, skuNames: $skuNames, transferType: $transferType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This API provides configuration details specific to given region/location.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataBox/locations/{location}/regionConfiguration
# operationId: Service_RegionConfiguration
# --scheduleAvailabilityRequest shape: {skuName: "DataBox"|"DataBoxDisk"|"DataBoxHeavy", storageLocation: string}
# --transportAvailabilityRequest shape: {skuName?: "DataBox"|"DataBoxDisk"|"DataBoxHeavy"}
export def "subscriptions-providers-microsoft-data-box-locations-region-configuration RegionConfiguration" [
  subscriptionId: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  --scheduleAvailabilityRequest: record # Request body to get the availability for scheduling orders. — shape: {skuName: "DataBox"|"DataBoxDisk"|"DataBoxHeavy", storageLocation: string}
  --transportAvailabilityRequest: record # Request body to get the transport availability for given sku. — shape: {skuName?: "DataBox"|"DataBoxDisk"|"DataBoxHeavy"}
]: any -> record<scheduleAvailabilityResponse: record<availableDates: list<string>>, transportAvailabilityResponse: record<transportAvailabilityDetails: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataBox/locations/($location)/regionConfiguration" $qp)
  let body = {scheduleAvailabilityRequest: $scheduleAvailabilityRequest, transportAvailabilityRequest: $transportAvailabilityRequest} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# [DEPRECATED NOTICE: This operation will soon be removed] This method validates the customer shipping address and provide alternate addresses if any.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataBox/locations/{location}/validateAddress
# DEPRECATED
# operationId: Service_ValidateAddress
# --shippingAddress shape: {addressType?: "None"|"Residential"|"Commercial", city?: string, companyName?: string, country: string, postalCode: string, stateOrProvince?: string, streetAddress1: string, streetAddress2?: string, streetAddress3?: string, zipExtendedCode?: string}
# --transportPreferences shape: {preferredShipmentType: "CustomerManaged"|"MicrosoftManaged"}
@deprecated
export def "subscriptions-providers-microsoft-data-box-locations-validate-address ValidateAddress" [
  subscriptionId: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  deviceType: string@deviceType-completer # Device type to be used for the job.
  shippingAddress: record # Shipping address where customer wishes to receive the device. — shape: {addressType?: "None"|"Residential"|"Commercial", city?: string, companyName?: string, country: string, postalCode: string, stateOrProvince?: string, streetAddress1: string, streetAddress2?: string, streetAddress3?: string, zipExtendedCode?: string}
  --transportPreferences: record # Preferences related to the shipment logistics of the sku — shape: {preferredShipmentType: "CustomerManaged"|"MicrosoftManaged"}
  validationType: string@validationType-completer # Identifies the type of validation request.
]: any -> record<properties: record<alternateAddresses: list<record>, validationStatus: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataBox/locations/($location)/validateAddress" $qp)
  let body = {deviceType: $deviceType, shippingAddress: $shippingAddress, transportPreferences: $transportPreferences, validationType: $validationType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method does all necessary pre-job creation validation under subscription.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.DataBox/locations/{location}/validateInputs
# Discriminator (request): validationCategory
# operationId: Service_ValidateInputs
# --individualRequestDetails item shape: {validationType: "ValidateAddress"|"ValidateDataDestinationDetails"|"ValidateSubscriptionIsAllowedToCreateJob"|"ValidatePreferences"|"ValidateCreateOrderLimit"|"ValidateSkuAvailability"}
export def "subscriptions-providers-microsoft-data-box-locations-validate-inputs ValidateInputs" [
  subscriptionId: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  individualRequestDetails: list # List of request details contain validationType and its request as key and value respectively. — item shape: {validationType: "ValidateAddress"|"ValidateDataDestinationDetails"|"ValidateSubscriptionIsAllowedToCreateJob"|"ValidatePreferences"|"ValidateCreateOrderLimit"|"ValidateSkuAvailability"}
  validationCategory: string@validationCategory-completer # Identify the nature of validation.
]: any -> record<properties: record<individualResponseDetails: list<record>, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.DataBox/locations/($location)/validateInputs" $qp)
  let body = {individualRequestDetails: $individualRequestDetails, validationCategory: $validationCategory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the jobs available under the given resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs
# operationId: Jobs_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs ListByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  --skipToken: string # $skipToken is supported on Get list of jobs, which provides the next page in the list of jobs.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$skipToken" $skipToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Deletes a job.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}
# operationId: Jobs_Delete
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs Delete" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
]: nothing -> record<code: string, details: list<any>, message: string, target: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about the specified job.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}
# operationId: Jobs_Get
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs Get" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  --expand: string # $expand is supported on details parameter for job, which provides details on the job stages.
]: nothing -> record<id: string, name: string, properties: record<cancellationReason: string, deliveryInfo: record<scheduledDateTime: string>, deliveryType: string, details: record<chainOfCustodySasKey: string, contactDetails: record, copyLogDetails: list, deliveryPackage: record, destinationAccountDetails: list, errorDetails: list, expectedDataSizeInTerabytes: int, jobDetailsType: string, jobStages: list, preferences: record, returnPackage: record, reverseShipmentLabelSasKey: string, shippingAddress: record>, error: record<code: string, message: string>, isCancellable: bool, isCancellableWithoutFee: bool, isDeletable: bool, isShippingAddressEditable: bool, startTime: string, status: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$expand" $expand "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates the properties of an existing job.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}
# operationId: Jobs_Update
# --properties shape: {destinationAccountDetails?: list, details?: record}
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs Update" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  --If-Match: string # Defines the If-Match condition. The patch will be performed only if the ETag of the job on the server matches this value.
  --properties: record # Job Properties for update — shape: {destinationAccountDetails?: list, details?: record}
  --tags: record # The list of key value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups).
]: any -> record<id: string, name: string, properties: record<cancellationReason: string, deliveryInfo: record<scheduledDateTime: string>, deliveryType: string, details: record<chainOfCustodySasKey: string, contactDetails: record, copyLogDetails: list, deliveryPackage: record, destinationAccountDetails: list, errorDetails: list, expectedDataSizeInTerabytes: int, jobDetailsType: string, jobStages: list, preferences: record, returnPackage: record, reverseShipmentLabelSasKey: string, shippingAddress: record>, error: record<code: string, message: string>, isCancellable: bool, isCancellableWithoutFee: bool, isDeletable: bool, isShippingAddressEditable: bool, startTime: string, status: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)" $qp)
  let body = {properties: $properties, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Creates a new job with the specified parameters. Existing job cannot be updated with this API and should instead be updated with the Update job API.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}
# operationId: Jobs_Create
# --properties shape: {deliveryInfo?: record, deliveryType?: "NonScheduled"|"Scheduled", details?: record, error?: record}
# --sku shape: {displayName?: string, family?: string, name: "DataBox"|"DataBoxDisk"|"DataBoxHeavy"}
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs Create" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  properties: record # Job Properties — shape: {deliveryInfo?: record, deliveryType?: "NonScheduled"|"Scheduled", details?: record, error?: record}
  location: string # The location of the resource. This will be one of the supported and registered Azure Regions (e.g. West US, East US, Southeast Asia, etc.). The region of a resource cannot be changed once it is created, but if an identical region is specified on update the request will succeed.
  sku: record # The Sku. — shape: {displayName?: string, family?: string, name: "DataBox"|"DataBoxDisk"|"DataBoxHeavy"}
  --tags: record # The list of key value pairs that describe the resource. These tags can be used in viewing and grouping this resource (across resource groups).
]: any -> record<id: string, name: string, properties: record<cancellationReason: string, deliveryInfo: record<scheduledDateTime: string>, deliveryType: string, details: record<chainOfCustodySasKey: string, contactDetails: record, copyLogDetails: list, deliveryPackage: record, destinationAccountDetails: list, errorDetails: list, expectedDataSizeInTerabytes: int, jobDetailsType: string, jobStages: list, preferences: record, returnPackage: record, reverseShipmentLabelSasKey: string, shippingAddress: record>, error: record<code: string, message: string>, isCancellable: bool, isCancellableWithoutFee: bool, isDeletable: bool, isShippingAddressEditable: bool, startTime: string, status: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)" $qp)
  let body = {properties: $properties, location: $location, sku: $sku, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Book shipment pick up.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}/bookShipmentPickUp
# operationId: Jobs_BookShipmentPickUp
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs-book-shipment-pick-up BookShipmentPickUp" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  endTime: string # Maximum date before which the pick up should commence, this must be in local time of pick up area. (format: date-time)
  shipmentLocation: string # Shipment Location in the pickup place. Eg.front desk
  startTime: string # Minimum date after which the pick up should commence, this must be in local time of pick up area. (format: date-time)
]: any -> record<confirmationNumber: string, readyByTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)/bookShipmentPickUp" $qp)
  let body = {endTime: $endTime, shipmentLocation: $shipmentLocation, startTime: $startTime} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# CancelJob.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}/cancel
# operationId: Jobs_Cancel
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs-cancel Cancel" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  reason: string # Reason for cancellation.
]: any -> record<code: string, details: list<any>, message: string, target: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)/cancel" $qp)
  let body = {reason: $reason} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method gets the unencrypted secrets related to the job.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/jobs/{jobName}/listCredentials
# operationId: Jobs_ListCredentials
export def "subscriptions-resource-groups-providers-microsoft-data-box-jobs-list-credentials ListCredentials" [
  subscriptionId: string
  resourceGroupName: string
  jobName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
]: nothing -> record<nextLink: string, value: table<jobName: string, jobSecrets: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/jobs/($jobName)/listCredentials" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# This method provides the list of available skus for the given subscription, resource group and location.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/locations/{location}/availableSkus
# operationId: Service_ListAvailableSkusByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-data-box-locations-available-skus ListAvailableSkusByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  country: string # ISO country code. Country for hardware shipment. For codes check: https://en.wikipedia.org/wiki/ISO_3166-1_alpha-2#Officially_assigned_code_elements
  --body-location: string # Location for data transfer. For locations check: https://management.azure.com/subscriptions/SUBSCRIPTIONID/locations?api-version=2018-01-01
  --skuNames: list # Sku Names to filter for available skus
  transferType: string@transferType-completer # Type of the transfer.
]: any -> record<nextLink: string, value: table<enabled: bool, properties: record, sku: record>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/locations/($location)/availableSkus" $qp)
  let body = {country: $country, location: $body_location, skuNames: $skuNames, transferType: $transferType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# This method does all necessary pre-job creation validation under resource group.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.DataBox/locations/{location}/validateInputs
# Discriminator (request): validationCategory
# operationId: Service_ValidateInputsByResourceGroup
# --individualRequestDetails item shape: {validationType: "ValidateAddress"|"ValidateDataDestinationDetails"|"ValidateSubscriptionIsAllowedToCreateJob"|"ValidatePreferences"|"ValidateCreateOrderLimit"|"ValidateSkuAvailability"}
export def "subscriptions-resource-groups-providers-microsoft-data-box-locations-validate-inputs ValidateInputsByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  location: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The API Version
  individualRequestDetails: list # List of request details contain validationType and its request as key and value respectively. — item shape: {validationType: "ValidateAddress"|"ValidateDataDestinationDetails"|"ValidateSubscriptionIsAllowedToCreateJob"|"ValidatePreferences"|"ValidateCreateOrderLimit"|"ValidateSkuAvailability"}
  validationCategory: string@validationCategory-completer # Identify the nature of validation.
]: any -> record<properties: record<individualResponseDetails: list<record>, status: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.DataBox/locations/($location)/validateInputs" $qp)
  let body = {individualRequestDetails: $individualRequestDetails, validationCategory: $validationCategory} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
