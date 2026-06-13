# Auto-generated client for Service Broker vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/servicebroker/v1beta1/openapi.json
# Auth: --token flag or $env.SERVICE_BROKER_TOKEN

const BASE_URL = "https://servicebroker.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_BROKER_TOKEN | default "" }
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

def base-url-completer [] { ["https://servicebroker.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1 bindingsdelete" } } | get name | first)
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

# Unbinds from a service instance. For synchronous/asynchronous request details see CreateServiceInstance method. If binding does not exist HTTP 410 status will be returned.
#
# DELETE /v1beta1/{name}
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.delete
export def "v1beta1 bindingsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --acceptsIncomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --planId: string # The plan id of the service instance.
  --serviceId: string # Additional query parameter hints. The service id of the service instance.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "acceptsIncomplete" $acceptsIncomplete "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "serviceId" $serviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# GetBinding returns the binding information.
#
# GET /v1beta1/{name}
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.get
export def "v1beta1 bindingsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --planId: string # Plan id.
  --serviceId: string # Service id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "serviceId" $serviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing service instance. See CreateServiceInstance for possible response codes.
#
# PATCH /v1beta1/{name}
# operationId: servicebroker.projects.brokers.v2.service_instances.patch
export def "v1beta1 instancespatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --acceptsIncomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --createTime: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deploymentName: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resourceName: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "acceptsIncomplete" $acceptsIncomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let body = {context: $context, createTime: $createTime, deploymentName: $deploymentName, description: $description, instance_id: $instance_id, organization_guid: $organization_guid, parameters: $parameters, plan_id: $plan_id, previous_values: $previous_values, resourceName: $resourceName, service_id: $service_id, space_guid: $space_guid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns the state of the last operation for the binding. Only last (or current) operation can be polled.
#
# GET /v1beta1/{name}/last_operation
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.getLast_operation
export def "v1beta1-last-operation operation" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --operation: string # If `operation` was returned during mutation operation, this field must be populated with the provided value.
  --planId: string # Plan id.
  --serviceId: string # Service id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "planId" $planId "scalar") (serialize-qp "serviceId" $serviceId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)/last_operation" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists all the bindings in the instance.
#
# GET /v1beta1/{parent}/bindings
# operationId: servicebroker.projects.brokers.instances.bindings.list
export def "v1beta1-bindings servicebrokerprojectsbrokersinstancesbindingslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --pageSize: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --pageToken: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/bindings" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# ListBrokers lists brokers.
#
# GET /v1beta1/{parent}/brokers
# operationId: servicebroker.projects.brokers.list
export def "v1beta1-brokers servicebrokerprojectsbrokerslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --pageSize: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --pageToken: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/brokers" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateBroker creates a Broker.
#
# POST /v1beta1/{parent}/brokers
# operationId: servicebroker.projects.brokers.create
export def "v1beta1-brokers servicebrokerprojectsbrokerscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --createTime: string # Output only. Timestamp for when the broker was created. (format: google-datetime)
  --name: string # Name of the broker in the format: <projects>/<project-id>/brokers/<broker>. This allows for multiple brokers per project which can be used to enable having custom brokers per GKE cluster, for example.
  --title: string # User friendly title of the broker. Limited to 1024 characters. Requests with longer titles will be rejected.
  --body-url: string # Output only. URL of the broker OSB-compliant endpoint, for example: https://servicebroker.googleapis.com/projects/<project>/brokers/<broker>
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/brokers" $qp)
  let body = {createTime: $createTime, name: $name, title: $title, url: $body_url} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the instances in the brokers This API is an extension and not part of the OSB spec. Hence the path is a standard Google API URL.
#
# GET /v1beta1/{parent}/instances
# operationId: servicebroker.projects.brokers.instances.list
export def "v1beta1-instances servicebrokerprojectsbrokersinstanceslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --pageSize: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --pageToken: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/instances" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# CreateBinding generates a service binding to an existing service instance. See ProviServiceInstance for async operation details.
#
# PUT /v1beta1/{parent}/service_bindings/{binding_id}
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.create
export def "v1beta1-service-bindings bindingscreate" [
  parent: string
  binding_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --acceptsIncomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --bind-resource: record # A JSON object that contains data for platform resources associated with the binding to be created.
  --body-binding-id: string # The id of the binding. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --createTime: string # Output only. Timestamp for when the binding was created. (format: google-datetime)
  --deploymentName: string # Output only. String containing the Deployment Manager deployment name that was created for this binding,
  --parameters: record # Configuration options for the service binding.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --resourceName: string # Output only. The resource name of the binding, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id/bindings/binding_id.
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "acceptsIncomplete" $acceptsIncomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/service_bindings/($binding_id)" $qp)
  let body = {bind_resource: $bind_resource, binding_id: $body_binding_id, createTime: $createTime, deploymentName: $deploymentName, parameters: $parameters, plan_id: $plan_id, resourceName: $resourceName, service_id: $service_id} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists all the Services registered with this broker for consumption for given service registry broker, which contains an set of services. Note, that Service producer API is separate from Broker API.
#
# GET /v1beta1/{parent}/v2/catalog
# operationId: servicebroker.projects.brokers.v2.catalog.list
export def "v1beta1-catalog servicebrokerprojectsbrokersv2cataloglist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --pageSize: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. If unset or 0, all the results will be returned.
  --pageToken: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/v2/catalog" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Provisions a service instance. If `request.accepts_incomplete` is false and Broker cannot execute request synchronously HTTP 422 error will be returned along with FAILED_PRECONDITION status. If `request.accepts_incomplete` is true and the Broker decides to execute resource asynchronously then HTTP 202 response code will be returned and a valid polling operation in the response will be included. If Broker executes the request synchronously and it succeeds HTTP 201 response will be furnished. If identical instance exists, then HTTP 200 response will be returned. If an instance with identical ID but mismatching parameters exists, then HTTP 409 status code will be returned.
#
# PUT /v1beta1/{parent}/v2/service_instances/{instance_id}
# operationId: servicebroker.projects.brokers.v2.service_instances.create
export def "v1beta1-service-instances instancescreate" [
  parent: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --acceptsIncomplete: oneof<nothing, bool> # Value indicating that API client supports asynchronous operations. If Broker cannot execute the request synchronously HTTP 422 code will be returned to HTTP clients along with FAILED_PRECONDITION error. If true and broker will execute request asynchronously 202 HTTP code will be returned. This broker always requires this to be true as all mutator operations are asynchronous.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --createTime: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deploymentName: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --body-instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resourceName: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "acceptsIncomplete" $acceptsIncomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/v2/service_instances/($instance_id)" $qp)
  let body = {context: $context, createTime: $createTime, deploymentName: $deploymentName, description: $description, instance_id: $body_instance_id, organization_guid: $organization_guid, parameters: $parameters, plan_id: $plan_id, previous_values: $previous_values, resourceName: $resourceName, service_id: $service_id, space_guid: $space_guid} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1beta1/{resource}:getIamPolicy
# operationId: servicebroker.getIamPolicy
export def "v1beta1 servicebrokergetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --optionsrequestedPolicyVersion: int # Optional. The policy format version to be returned.  Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected.  Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "options.requestedPolicyVersion" $optionsrequestedPolicyVersion "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):getIamPolicy" $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the access control policy on the specified resource. Replaces any existing policy.  Can return Public Errors: NOT_FOUND, INVALID_ARGUMENT and PERMISSION_DENIED
#
# POST /v1beta1/{resource}:setIamPolicy
# operationId: servicebroker.setIamPolicy
# --policy shape: {bindings?: list, etag?: string, version?: int}
export def "v1beta1 servicebrokersetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources.   A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role.  Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both.  **JSON example:**      {       "bindings": [         {           "role": "roles/resourcemanager.organizationAdmin",           "members": [             "user:mike@example.com",             "group:admins@example.com",             "domain:google.com",             "serviceAccount:my-project-id@appspot.gserviceaccount.com"           ]         },         {           "role": "roles/resourcemanager.organizationViewer",           "members": ["user:eve@example.com"],           "condition": {             "title": "expirable access",             "description": "Does not grant access after Sep 2020",             "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')",           }         }       ],       "etag": "BwWWja0YfJA=",       "version": 3     }  **YAML example:**      bindings:     - members:       - user:mike@example.com       - group:admins@example.com       - domain:google.com       - serviceAccount:my-project-id@appspot.gserviceaccount.com       role: roles/resourcemanager.organizationAdmin     - members:       - user:eve@example.com       role: roles/resourcemanager.organizationViewer       condition:         title: expirable access         description: Does not grant access after Sep 2020         expression: request.time < timestamp('2020-10-01T00:00:00.000Z')     - etag: BwWWja0YfJA=     - version: 3  For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):setIamPolicy" $qp)
  let body = {policy: $policy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a NOT_FOUND error.  Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1beta1/{resource}:testIamPermissions
# operationId: servicebroker.testIamPermissions
export def "v1beta1 servicebrokertestIamPermissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --permissions: list # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "fields" $qp_fields "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($resource):testIamPermissions" $qp)
  let body = {permissions: $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
