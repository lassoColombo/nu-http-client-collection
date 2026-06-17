# Auto-generated client for Azure Media Services v2019-05-01-preview
# Source: https://api.apis.guru/v2/specs/azure.com/mediaservices-streamingservice/2019-05-01-preview/swagger.json
# Auth: --token flag or $env.AZURE_MEDIA_SERVICES_TOKEN

const BASE_URL = "https://management.azure.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o AZURE_MEDIA_SERVICES_TOKEN | default "" }
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


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events list" } } | get name | first)
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

# List Live Events
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents
# operationId: LiveEvents_List
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<_odata_count: int, _odata_nextLink: string, value: table<properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Live Event
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}
# operationId: LiveEvents_Delete
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Live Event
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}
# operationId: LiveEvents_Get
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<properties: record<created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, description: string, encoding: record<encodingType: string, presetName: string>, input: record<accessControl: record, accessToken: string, endpoints: list, keyFrameIntervalDuration: string, streamingProtocol: string>, lastModified: string, preview: record<accessControl: record, alternativeMediaId: string, endpoints: list, previewLocator: string, streamingPolicyName: string>, provisioningState: string, resourceState: string, streamOptions: list<string>, transcriptions: list<record>, vanityUrl: bool>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a existing Live Event.
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}
# operationId: LiveEvents_Update
# --properties shape: {crossSiteAccessPolicies?: any, description?: string, encoding?: any, input: any, preview?: any, streamOptions?: list, transcriptions?: list, vanityUrl?: bool}
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --properties: any # The Live Event properties. — shape: {crossSiteAccessPolicies?: any, description?: string, encoding?: any, input: any, preview?: any, streamOptions?: list, transcriptions?: list, vanityUrl?: bool}
  --location: string # The Azure Region of the resource.
  --tags: record # Resource tags.
]: any -> record<properties: record<created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, description: string, encoding: record<encodingType: string, presetName: string>, input: record<accessControl: record, accessToken: string, endpoints: list, keyFrameIntervalDuration: string, streamingProtocol: string>, lastModified: string, preview: record<accessControl: record, alternativeMediaId: string, endpoints: list, previewLocator: string, streamingPolicyName: string>, provisioningState: string, resourceState: string, streamOptions: list<string>, transcriptions: list<record>, vanityUrl: bool>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create Live Event
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}
# operationId: LiveEvents_Create
# --properties shape: {crossSiteAccessPolicies?: any, description?: string, encoding?: any, input: any, preview?: any, streamOptions?: list, transcriptions?: list, vanityUrl?: bool}
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --auto-start: oneof<nothing, bool> # The flag indicates if the resource should be automatically started on creation.
  --properties: any # The Live Event properties. — shape: {crossSiteAccessPolicies?: any, description?: string, encoding?: any, input: any, preview?: any, streamOptions?: list, transcriptions?: list, vanityUrl?: bool}
  --location: string # The Azure Region of the resource.
  --tags: record # Resource tags.
]: any -> record<properties: record<created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, description: string, encoding: record<encodingType: string, presetName: string>, input: record<accessControl: record, accessToken: string, endpoints: list, keyFrameIntervalDuration: string, streamingProtocol: string>, lastModified: string, preview: record<accessControl: record, alternativeMediaId: string, endpoints: list, previewLocator: string, streamingPolicyName: string>, provisioningState: string, resourceState: string, streamOptions: list<string>, transcriptions: list<record>, vanityUrl: bool>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "autoStart" $auto_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List Live Outputs
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/liveOutputs
# operationId: LiveOutputs_List
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-live-outputs list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<_odata_count: int, _odata_nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/liveOutputs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete Live Output
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/liveOutputs/{liveOutputName}
# operationId: LiveOutputs_Delete
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-live-outputs delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  live_output_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name, live_output_name: $live_output_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/liveOutputs/{live_output_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get Live Output
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/liveOutputs/{liveOutputName}
# operationId: LiveOutputs_Get
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-live-outputs get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  live_output_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<properties: record<archiveWindowLength: string, assetName: string, created: string, description: string, hls: record<fragmentsPerTsSegment: int>, lastModified: string, manifestName: string, outputSnapTime: int, provisioningState: string, resourceState: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name, live_output_name: $live_output_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/liveOutputs/{live_output_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create Live Output
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/liveOutputs/{liveOutputName}
# operationId: LiveOutputs_Create
# --properties shape: {archiveWindowLength: string, assetName: string, description?: string, hls?: any, manifestName?: string, outputSnapTime?: int}
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-live-outputs create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  live_output_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --properties: any # The JSON object that contains the properties required to create a Live Output. — shape: {archiveWindowLength: string, assetName: string, description?: string, hls?: any, manifestName?: string, outputSnapTime?: int}
]: any -> record<properties: record<archiveWindowLength: string, assetName: string, created: string, description: string, hls: record<fragmentsPerTsSegment: int>, lastModified: string, manifestName: string, outputSnapTime: int, provisioningState: string, resourceState: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name, live_output_name: $live_output_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/liveOutputs/{live_output_name}") $qp)
  let body = {"properties": $properties} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Reset Live Event
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/reset
# operationId: LiveEvents_Reset
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-reset reset" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/reset") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Start Live Event
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/start
# operationId: LiveEvents_Start
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-start start" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop Live Event
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/liveEvents/{liveEventName}/stop
# operationId: LiveEvents_Stop
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-live-events-stop stop" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  live_event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --remove-outputs-on-stop: oneof<nothing, bool> # The flag indicates if remove LiveOutputs on Stop.
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, live_event_name: $live_event_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/liveEvents/{live_event_name}/stop") $qp)
  let body = {"removeOutputsOnStop": $remove_outputs_on_stop} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# List StreamingEndpoints
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints
# operationId: StreamingEndpoints_List
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints list" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<_odata_count: int, _odata_nextLink: string, value: table<properties: record, location: string, tags: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Delete StreamingEndpoint
#
# DELETE /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}
# operationId: StreamingEndpoints_Delete
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints delete" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get StreamingEndpoint
#
# GET /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}
# operationId: StreamingEndpoints_Get
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints get" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<properties: record<accessControl: record<akamai: record, ip: record>, availabilitySetName: string, cdnEnabled: bool, cdnProfile: string, cdnProvider: string, created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, customHostNames: list<string>, description: string, freeTrialEndTime: string, hostName: string, lastModified: string, maxCacheAge: int, provisioningState: string, resourceState: string, scaleUnits: int>, location: string, tags: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update StreamingEndpoint
#
# PATCH /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}
# operationId: StreamingEndpoints_Update
# --properties shape: {accessControl?: any, availabilitySetName?: string, cdnEnabled?: bool, cdnProfile?: string, cdnProvider?: string, crossSiteAccessPolicies?: any, customHostNames?: list, description?: string, maxCacheAge?: int, scaleUnits: int}
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints update" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --properties: any # The StreamingEndpoint properties. — shape: {accessControl?: any, availabilitySetName?: string, cdnEnabled?: bool, cdnProfile?: string, cdnProvider?: string, crossSiteAccessPolicies?: any, customHostNames?: list, description?: string, maxCacheAge?: int, scaleUnits: int}
  --location: string # The Azure Region of the resource.
  --tags: record # Resource tags.
]: any -> record<properties: record<accessControl: record<akamai: record, ip: record>, availabilitySetName: string, cdnEnabled: bool, cdnProfile: string, cdnProvider: string, created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, customHostNames: list<string>, description: string, freeTrialEndTime: string, hostName: string, lastModified: string, maxCacheAge: int, provisioningState: string, resourceState: string, scaleUnits: int>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Create StreamingEndpoint
#
# PUT /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}
# operationId: StreamingEndpoints_Create
# --properties shape: {accessControl?: any, availabilitySetName?: string, cdnEnabled?: bool, cdnProfile?: string, cdnProvider?: string, crossSiteAccessPolicies?: any, customHostNames?: list, description?: string, maxCacheAge?: int, scaleUnits: int}
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints create" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --auto-start: oneof<nothing, bool> # The flag indicates if the resource should be automatically started on creation.
  --properties: any # The StreamingEndpoint properties. — shape: {accessControl?: any, availabilitySetName?: string, cdnEnabled?: bool, cdnProfile?: string, cdnProvider?: string, crossSiteAccessPolicies?: any, customHostNames?: list, description?: string, maxCacheAge?: int, scaleUnits: int}
  --location: string # The Azure Region of the resource.
  --tags: record # Resource tags.
]: any -> record<properties: record<accessControl: record<akamai: record, ip: record>, availabilitySetName: string, cdnEnabled: bool, cdnProfile: string, cdnProvider: string, created: string, crossSiteAccessPolicies: record<clientAccessPolicy: string, crossDomainPolicy: string>, customHostNames: list<string>, description: string, freeTrialEndTime: string, hostName: string, lastModified: string, maxCacheAge: int, provisioningState: string, resourceState: string, scaleUnits: int>, location: string, tags: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "autoStart" $auto_start "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}") $qp)
  let body = {"properties": $properties, "location": $location, "tags": $tags} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Scale StreamingEndpoint
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}/scale
# operationId: StreamingEndpoints_Scale
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints-scale post" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
  --scale-unit: int # The scale unit number of the StreamingEndpoint. (format: int32)
]: any -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}/scale") $qp)
  let body = {"scaleUnit": $scale_unit} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Start StreamingEndpoint
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}/start
# operationId: StreamingEndpoints_Start
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints-start start" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}/start") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Stop StreamingEndpoint
#
# POST /subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Media/mediaservices/{accountName}/streamingEndpoints/{streamingEndpointName}/stop
# operationId: StreamingEndpoints_Stop
export def "subscriptions-resource-groups-providers-microsoft-media-mediaservices-streaming-endpoints-stop stop" [
  subscription_id: string
  resource_group_name: string
  account_name: string
  streaming_endpoint_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # The Version of the API to be used with the client request.
]: nothing -> record<error: record<code: string, details: list<any>, message: string, target: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: $subscription_id, resource_group_name: $resource_group_name, account_name: $account_name, streaming_endpoint_name: $streaming_endpoint_name} | format pattern "/subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Media/mediaservices/{account_name}/streamingEndpoints/{streaming_endpoint_name}/stop") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
