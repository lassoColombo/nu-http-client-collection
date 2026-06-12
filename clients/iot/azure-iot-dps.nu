# Auto-generated client for iotDpsClient v2018-01-22
# Source: https://api.apis.guru/v2/specs/azure.com/deviceprovisioningservices-iotdps/2018-01-22/swagger.json
# Auth: --token flag or $env.IOTDPSCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o IOTDPSCLIENT_TOKEN | default "" }
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
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, max_time?: duration, allow_errors?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
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
def certificatepurpose-completer [] { ["clientAuthentication" "serverAuthentication"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "providers-microsoft-devices-operations List" } } | get name | first)
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

# Lists all of the available Microsoft.Devices REST API operations.
#
# GET /providers/Microsoft.Devices/operations
# operationId: Operations_List
export def "providers-microsoft-devices-operations List" [
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<nextLink: string, value: table<display: record, name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base "/providers/Microsoft.Devices/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Check if a provisioning service name is available.
#
# POST /subscriptions/{subscriptionId}/providers/Microsoft.Devices/checkProvisioningServiceNameAvailability
# operationId: IotDpsResource_CheckProvisioningServiceNameAvailability
export def "subscriptions-providers-microsoft-devices-check-provisioning-service-name-availability CheckProvisioningServiceNameAvailability" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
  name: string # The name of the Provisioning Service to check.
]: any -> record<message: string, nameAvailable: bool, reason: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Devices/checkProvisioningServiceNameAvailability" $qp)
  let body = {name: $name} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all the provisioning services in a subscription.
#
# GET /subscriptions/{subscriptionId}/providers/Microsoft.Devices/provisioningServices
# operationId: IotDpsResource_ListBySubscription
export def "subscriptions-providers-microsoft-devices-provisioning-services ListBySubscription" [
  subscriptionId: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/providers/Microsoft.Devices/provisioningServices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get a list of all provisioning services in the given resource group.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices
# operationId: IotDpsResource_ListByResourceGroup
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services ListByResourceGroup" [
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<nextLink: string, value: table<etag: string, properties: record, sku: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Provisioning Service
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}
# operationId: IotDpsResource_Delete
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services Delete" [
  provisioningServiceName: string
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<code: string, details: string, httpStatusCode: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the non-security related metadata of the provisioning service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}
# operationId: IotDpsResource_Get
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services Get" [
  provisioningServiceName: string
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<etag: string, properties: record<allocationPolicy: string, authorizationPolicies: list<record>, deviceProvisioningHostName: string, idScope: string, iotHubs: list<record>, provisioningState: string, serviceOperationsHostName: string, state: string>, sku: record<capacity: int, name: string, tier: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Update an existing provisioning service's tags.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}
# operationId: IotDpsResource_Update
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services Update" [
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
  --tags: any # Resource tags
]: any -> record<etag: string, properties: record<allocationPolicy: string, authorizationPolicies: list<record>, deviceProvisioningHostName: string, idScope: string, iotHubs: list<record>, provisioningState: string, serviceOperationsHostName: string, state: string>, sku: record<capacity: int, name: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)" $qp)
  let body = {tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Create or update the metadata of the provisioning service.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}
# operationId: IotDpsResource_CreateOrUpdate
# --properties shape: {allocationPolicy?: "Hashed"|"GeoLatency"|"Static", authorizationPolicies?: list, iotHubs?: list, provisioningState?: string, state?: "Activating"|"Active"|"Deleting"|"Deleted"|"ActivationFailed"|"DeletionFailed"|"Transitioning"|"Suspending"|"Suspended"|"Resuming"|"FailingOver"|"FailoverFailed"}
# --sku shape: {capacity?: int, name?: "S1"}
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
  --etag: string # The Etag field is *not* required. If it is provided in the response body, it must also be provided as a header per the normal ETag convention.
  properties: record # the service specific properties of a provisioning service, including keys, linked iot hubs, current state, and system generated properties such as hostname and idScope — shape: {allocationPolicy?: "Hashed"|"GeoLatency"|"Static", authorizationPolicies?: list, iotHubs?: list, provisioningState?: string, state?: "Activating"|"Active"|"Deleting"|"Deleted"|"ActivationFailed"|"DeletionFailed"|"Transitioning"|"Suspending"|"Suspended"|"Resuming"|"FailingOver"|"FailoverFailed"}
  sku: record # List of possible provisioning service SKUs. — shape: {capacity?: int, name?: "S1"}
  location: string # The resource location.
  --tags: record # The resource tags.
]: any -> record<etag: string, properties: record<allocationPolicy: string, authorizationPolicies: list<record>, deviceProvisioningHostName: string, idScope: string, iotHubs: list<record>, provisioningState: string, serviceOperationsHostName: string, state: string>, sku: record<capacity: int, name: string, tier: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)" $qp)
  let body = {etag: $etag, properties: $properties, sku: $sku, location: $location, tags: $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get all the certificates tied to the provisioning service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates
# operationId: DpsCertificate_List
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates List" [
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<value: table<etag: string, id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Delete the Provisioning Service Certificate.
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates/{certificateName}
# operationId: DpsCertificate_Delete
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates Delete" [
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  certificateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificatename: string # This is optional, and it is the Common Name of the certificate.
  --certificaterawBytes: string # Raw data within the certificate. (format: byte)
  --certificateisVerified: oneof<nothing, bool> # Indicates if certificate has been verified by owner of the private key.
  --certificatepurpose: string@certificatepurpose-completer # A description that mentions the purpose of the certificate.
  --certificatecreated: string # Time the certificate is created. (format: date-time)
  --certificatelastUpdated: string # Time the certificate is last updated. (format: date-time)
  --certificatehasPrivateKey: oneof<nothing, bool> # Indicates if the certificate contains a private key.
  --certificatenonce: string # Random number generated to indicate Proof of Possession.
  --api-version: string # The version of the API.
  --If-Match: string # ETag of the certificate
]: nothing -> record<code: string, details: string, httpStatusCode: string, message: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certificate.name" $certificatename "scalar") (serialize-qp "certificate.rawBytes" $certificaterawBytes "scalar") (serialize-qp "certificate.isVerified" $certificateisVerified "scalar") (serialize-qp "certificate.purpose" $certificatepurpose "scalar") (serialize-qp "certificate.created" $certificatecreated "scalar") (serialize-qp "certificate.lastUpdated" $certificatelastUpdated "scalar") (serialize-qp "certificate.hasPrivateKey" $certificatehasPrivateKey "scalar") (serialize-qp "certificate.nonce" $certificatenonce "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates/($certificateName)" $qp)
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the certificate from the provisioning service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates/{certificateName}
# operationId: DpsCertificate_Get
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates Get" [
  certificateName: string
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
  --If-Match: string # ETag of the certificate.
]: nothing -> record<etag: string, id: string, name: string, properties: record<created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates/($certificateName)" $qp)
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Upload the certificate to the provisioning service.
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates/{certificateName}
# operationId: DpsCertificate_CreateOrUpdate
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates CreateOrUpdate" [
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  certificateName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
  --If-Match: string # ETag of the certificate. This is required to update an existing certificate, and ignored while creating a brand new certificate.
  --certificate: string # Base-64 representation of the X509 leaf certificate .cer file or just .pem file content.
]: any -> record<etag: string, id: string, name: string, properties: record<created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates/($certificateName)" $qp)
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Generate verification code for Proof of Possession.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates/{certificateName}/generateVerificationCode
# operationId: DpsCertificate_GenerateVerificationCode
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates-generate-verification-code GenerateVerificationCode" [
  certificateName: string
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificatename: string # Common Name for the certificate.
  --certificaterawBytes: string # Raw data of certificate. (format: byte)
  --certificateisVerified: oneof<nothing, bool> # Indicates if the certificate has been verified by owner of the private key.
  --certificatepurpose: string@certificatepurpose-completer # Description mentioning the purpose of the certificate.
  --certificatecreated: string # Certificate creation time. (format: date-time)
  --certificatelastUpdated: string # Certificate last updated time. (format: date-time)
  --certificatehasPrivateKey: oneof<nothing, bool> # Indicates if the certificate contains private key.
  --certificatenonce: string # Random number generated to indicate Proof of Possession.
  --api-version: string # The version of the API.
  --If-Match: string # ETag of the certificate. This is required to update an existing certificate, and ignored while creating a brand new certificate.
]: nothing -> record<etag: string, id: string, name: string, properties: record<created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string, verificationCode: string>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certificate.name" $certificatename "scalar") (serialize-qp "certificate.rawBytes" $certificaterawBytes "scalar") (serialize-qp "certificate.isVerified" $certificateisVerified "scalar") (serialize-qp "certificate.purpose" $certificatepurpose "scalar") (serialize-qp "certificate.created" $certificatecreated "scalar") (serialize-qp "certificate.lastUpdated" $certificatelastUpdated "scalar") (serialize-qp "certificate.hasPrivateKey" $certificatehasPrivateKey "scalar") (serialize-qp "certificate.nonce" $certificatenonce "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates/($certificateName)/generateVerificationCode" $qp)
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Verify certificate's private key possession.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/certificates/{certificateName}/verify
# operationId: DpsCertificate_VerifyCertificate
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-certificates-verify VerifyCertificate" [
  certificateName: string
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --certificatename: string # Common Name for the certificate.
  --certificaterawBytes: string # Raw data of certificate. (format: byte)
  --certificateisVerified: oneof<nothing, bool> # Indicates if the certificate has been verified by owner of the private key.
  --certificatepurpose: string@certificatepurpose-completer # Describe the purpose of the certificate.
  --certificatecreated: string # Certificate creation time. (format: date-time)
  --certificatelastUpdated: string # Certificate last updated time. (format: date-time)
  --certificatehasPrivateKey: oneof<nothing, bool> # Indicates if the certificate contains private key.
  --certificatenonce: string # Random number generated to indicate Proof of Possession.
  --api-version: string # The version of the API.
  --If-Match: string # ETag of the certificate.
  --certificate: string # base-64 representation of X509 certificate .cer file or just .pem file content.
]: any -> record<etag: string, id: string, name: string, properties: record<created: string, expiry: string, isVerified: bool, subject: string, thumbprint: string, updated: string>, type: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "certificate.name" $certificatename "scalar") (serialize-qp "certificate.rawBytes" $certificaterawBytes "scalar") (serialize-qp "certificate.isVerified" $certificateisVerified "scalar") (serialize-qp "certificate.purpose" $certificatepurpose "scalar") (serialize-qp "certificate.created" $certificatecreated "scalar") (serialize-qp "certificate.lastUpdated" $certificatelastUpdated "scalar") (serialize-qp "certificate.hasPrivateKey" $certificatehasPrivateKey "scalar") (serialize-qp "certificate.nonce" $certificatenonce "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/certificates/($certificateName)/verify" $qp)
  let body = {certificate: $certificate} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let extra_headers = {"If-Match": $If_Match} | compact
  let auth = ($auth | update headers ($auth.headers | merge $extra_headers))
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json" $body
}

# Get a shared access policy by name from a provisioning service.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/keys/{keyName}/listkeys
# operationId: IotDpsResource_ListKeysForKeyName
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-keys-listkeys ListKeysForKeyName" [
  provisioningServiceName: string
  keyName: string
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<keyName: string, primaryKey: string, rights: string, secondaryKey: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/keys/($keyName)/listkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the security metadata for a provisioning service.
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/listkeys
# operationId: IotDpsResource_ListKeys
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-listkeys ListKeys" [
  provisioningServiceName: string
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<nextLink: string, value: table<keyName: string, primaryKey: string, rights: string, secondaryKey: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/listkeys" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Gets the status of a long running operation, such as create, update or delete a provisioning service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/operationresults/{operationId}
# operationId: IotDpsResource_GetOperationResult
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-operationresults GetOperationResult" [
  operationId: string
  subscriptionId: string
  resourceGroupName: string
  provisioningServiceName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --asyncinfo: string # Async header used to poll on the status of the operation, obtained while creating the long running operation. (default: true)
  --api-version: string # The version of the API.
]: nothing -> record<error: record<code: string, details: string, message: string>, status: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "asyncinfo" $asyncinfo "scalar") (serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/operationresults/($operationId)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}

# Get the list of valid SKUs for a provisioning service.
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Devices/provisioningServices/{provisioningServiceName}/skus
# operationId: IotDpsResource_listValidSkus
export def "subscriptions-resource-groups-providers-microsoft-devices-provisioning-services-skus listValidSkus" [
  provisioningServiceName: string
  subscriptionId: string
  resourceGroupName: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --api-version: string # The version of the API.
]: nothing -> record<nextLink: string, value: table<name: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/subscriptions/($subscriptionId)/resourceGroups/($resourceGroupName)/providers/Microsoft.Devices/provisioningServices/($provisioningServiceName)/skus" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $max_time $allow_errors "application/json"
}
