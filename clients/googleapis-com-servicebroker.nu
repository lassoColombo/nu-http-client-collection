# Auto-generated client for Service Broker vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/servicebroker/v1beta1/openapi.json
# Auth: --token flag or $env.SERVICE_BROKER_TOKEN

const BASE_URL = "https://servicebroker.googleapis.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SERVICE_BROKER_TOKEN | default "" }
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
# Trick: `url encode --all` over-encodes, then we decode the four unreserved
# punctuation chars back. Pre-existing %XX sequences in the input survive
# because `url encode --all` first turns their % into %25.
def encode-path-segment [v: any]: nothing -> string {
  $v | into string | url encode --all | str replace --all "%2D" "-" | str replace --all "%2E" "." | str replace --all "%5F" "_" | str replace --all "%7E" "~"
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

def base-url-completer [] { ["https://servicebroker.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1 delete" } } | get name | first)
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
export def "v1beta1 delete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --plan-id: string # The plan id of the service instance.
  --service-id: string # Additional query parameter hints. The service id of the service instance.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "acceptsIncomplete" $accepts_incomplete "scalar") (serialize-qp "planId" $plan_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "acceptsIncomplete": $accepts_incomplete, "planId": $plan_id, "serviceId": $service_id} | compact), body: null}
}

# GetBinding returns the binding information.
#
# GET /v1beta1/{name}
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.get
export def "v1beta1 get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --plan-id: string # Plan id.
  --service-id: string # Service id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "planId" $plan_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "planId": $plan_id, "serviceId": $service_id} | compact), body: null}
}

# Updates an existing service instance. See CreateServiceInstance for possible response codes.
#
# PATCH /v1beta1/{name}
# operationId: servicebroker.projects.brokers.v2.service_instances.patch
export def "v1beta1 update" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --create-time: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resource-name: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "acceptsIncomplete" $accepts_incomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}") $qp)
  let req_body = {"context": $context, "createTime": $create_time, "deploymentName": $deployment_name, "description": $description, "instance_id": $instance_id, "organization_guid": $organization_guid, "parameters": $parameters, "plan_id": $plan_id, "previous_values": $previous_values, "resourceName": $resource_name, "service_id": $service_id, "space_guid": $space_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "acceptsIncomplete": $accepts_incomplete} | compact), body: $req_body}
}

# Returns the state of the last operation for the binding. Only last (or current) operation can be polled.
#
# GET /v1beta1/{name}/last_operation
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.getLast_operation
export def "v1beta1-last-operation get" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --operation: string # If `operation` was returned during mutation operation, this field must be populated with the provided value.
  --plan-id: string # Plan id.
  --service-id: string # Service id.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($name | is-empty) { error make --unspanned { msg: "path parameter 'name' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "operation" $operation "scalar") (serialize-qp "planId" $plan_id "scalar") (serialize-qp "serviceId" $service_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta1/{name}/last_operation") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "operation": $operation, "planId": $plan_id, "serviceId": $service_id} | compact), body: null}
}

# Lists all the bindings in the instance.
#
# GET /v1beta1/{parent}/bindings
# operationId: servicebroker.projects.brokers.instances.bindings.list
export def "v1beta1-bindings list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/bindings") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# ListBrokers lists brokers.
#
# GET /v1beta1/{parent}/brokers
# operationId: servicebroker.projects.brokers.list
export def "v1beta1-brokers list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/brokers") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# CreateBroker creates a Broker.
#
# POST /v1beta1/{parent}/brokers
# operationId: servicebroker.projects.brokers.create
export def "v1beta1-brokers create" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --create-time: string # Output only. Timestamp for when the broker was created. (format: google-datetime)
  --name: string # Name of the broker in the format: /<project-id>/brokers/. This allows for multiple brokers per project which can be used to enable having custom brokers per GKE cluster, for example.
  --title: string # User friendly title of the broker. Limited to 1024 characters. Requests with longer titles will be rejected.
  --url: string # Output only. URL of the broker OSB-compliant endpoint, for example: https://servicebroker.googleapis.com/projects//brokers/
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/brokers") $qp)
  let req_body = {"createTime": $create_time, "name": $name, "title": $title, "url": $url} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print} | compact), body: $req_body}
}

# Lists all the instances in the brokers This API is an extension and not part of the OSB spec. Hence the path is a standard Google API URL.
#
# GET /v1beta1/{parent}/instances
# operationId: servicebroker.projects.brokers.instances.list
export def "v1beta1-instances list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. Acceptable values are 0 to 200, inclusive. (Default: 100)
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/instances") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# CreateBinding generates a service binding to an existing service instance. See ProviServiceInstance for async operation details.
#
# PUT /v1beta1/{parent}/service_bindings/{binding_id}
# operationId: servicebroker.projects.brokers.v2.service_instances.service_bindings.create
export def "v1beta1-service-bindings create" [
  parent: string
  binding_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # See CreateServiceInstanceRequest for details.
  --bind-resource: record # A JSON object that contains data for platform resources associated with the binding to be created.
  --body-binding-id: string # The id of the binding. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --create-time: string # Output only. Timestamp for when the binding was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this binding,
  --parameters: record # Configuration options for the service binding.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --resource-name: string # Output only. The resource name of the binding, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id/bindings/binding_id.
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  if ($binding_id | is-empty) { error make --unspanned { msg: "path parameter 'binding_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "acceptsIncomplete" $accepts_incomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent), binding_id: (encode-path-segment $binding_id)} | format pattern "/v1beta1/{parent}/service_bindings/{binding_id}") $qp)
  let req_body = {"bind_resource": $bind_resource, "binding_id": $body_binding_id, "createTime": $create_time, "deploymentName": $deployment_name, "parameters": $parameters, "plan_id": $plan_id, "resourceName": $resource_name, "service_id": $service_id} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "acceptsIncomplete": $accepts_incomplete} | compact), body: $req_body}
}

# Lists all the Services registered with this broker for consumption for given service registry broker, which contains an set of services. Note, that Service producer API is separate from Broker API.
#
# GET /v1beta1/{parent}/v2/catalog
# operationId: servicebroker.projects.brokers.v2.catalog.list
export def "v1beta1-catalog list" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --page-size: int # Specifies the number of results to return per page. If there are fewer elements than the specified number, returns all elements. Optional. If unset or 0, all the results will be returned.
  --page-token: string # Specifies a page token to use. Set `pageToken` to a `nextPageToken` returned by a previous list request to get the next page of results.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta1/{parent}/v2/catalog") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "pageSize": $page_size, "pageToken": $page_token} | compact), body: null}
}

# Provisions a service instance. If `request.accepts_incomplete` is false and Broker cannot execute request synchronously HTTP 422 error will be returned along with FAILED_PRECONDITION status. If `request.accepts_incomplete` is true and the Broker decides to execute resource asynchronously then HTTP 202 response code will be returned and a valid polling operation in the response will be included. If Broker executes the request synchronously and it succeeds HTTP 201 response will be furnished. If identical instance exists, then HTTP 200 response will be returned. If an instance with identical ID but mismatching parameters exists, then HTTP 409 status code will be returned.
#
# PUT /v1beta1/{parent}/v2/service_instances/{instance_id}
# operationId: servicebroker.projects.brokers.v2.service_instances.create
export def "v1beta1-service-instances create" [
  parent: string
  instance_id: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --accepts-incomplete: oneof<nothing, bool> # Value indicating that API client supports asynchronous operations. If Broker cannot execute the request synchronously HTTP 422 code will be returned to HTTP clients along with FAILED_PRECONDITION error. If true and broker will execute request asynchronously 202 HTTP code will be returned. This broker always requires this to be true as all mutator operations are asynchronous.
  --context: record # Platform specific contextual information under which the service instance is to be provisioned. This replaces organization_guid and space_guid. But can also contain anything. Currently only used for logging context information.
  --create-time: string # Output only. Timestamp for when the instance was created. (format: google-datetime)
  --deployment-name: string # Output only. String containing the Deployment Manager deployment name that was created for this instance,
  --description: string # To return errors when GetInstance call is done via HTTP to be unified with other methods.
  --body-instance-id: string # The id of the service instance. Must be unique within GCP project. Maximum length is 64, GUID recommended. Required.
  --organization-guid: string # The platform GUID for the organization under which the service is to be provisioned. Required.
  --parameters: record # Configuration options for the service instance. Parameters is JSON object serialized to string.
  --plan-id: string # The ID of the plan. See `Service` and `Plan` resources for details. Maximum length is 64, GUID recommended. Required.
  --previous-values: record # Used only in UpdateServiceInstance request to optionally specify previous fields.
  --resource-name: string # Output only. The resource name of the instance, e.g. projects/project_id/brokers/broker_id/service_instances/instance_id
  --service-id: string # The id of the service. Must be a valid identifier of a service contained in the list from a `ListServices()` call. Maximum length is 64, GUID recommended. Required.
  --space-guid: string # The identifier for the project space within the platform organization. Required.
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($parent | is-empty) { error make --unspanned { msg: "path parameter 'parent' must be non-empty" } }
  if ($instance_id | is-empty) { error make --unspanned { msg: "path parameter 'instance_id' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "acceptsIncomplete" $accepts_incomplete "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent), instance_id: (encode-path-segment $instance_id)} | format pattern "/v1beta1/{parent}/v2/service_instances/{instance_id}") $qp)
  let req_body = {"context": $context, "createTime": $create_time, "deploymentName": $deployment_name, "description": $description, "instance_id": $body_instance_id, "organization_guid": $organization_guid, "parameters": $parameters, "plan_id": $plan_id, "previous_values": $previous_values, "resourceName": $resource_name, "service_id": $service_id, "space_guid": $space_guid} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "acceptsIncomplete": $accepts_incomplete} | compact), body: $req_body}
}

# Gets the access control policy for a resource. Returns an empty policy if the resource exists and does not have a policy set.
#
# GET /v1beta1/{resource}:getIamPolicy
# operationId: servicebroker.getIamPolicy
export def "v1beta1 get-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --options-requested-policy-version: int # Optional. The policy format version to be returned. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional bindings must specify version 3. Policies without any conditional bindings may specify any valid value or leave the field unset.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "options.requestedPolicyVersion" $options_requested_policy_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:getIamPolicy") $qp)
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print, "options.requestedPolicyVersion": $options_requested_policy_version} | compact), body: null}
}

# Sets the access control policy on the specified resource. Replaces any existing policy. Can return Public Errors: NOT_FOUND, INVALID_ARGUMENT and PERMISSION_DENIED
#
# POST /v1beta1/{resource}:setIamPolicy
# operationId: servicebroker.setIamPolicy
# --policy shape: {bindings?: list, etag?: string, version?: int}
export def "v1beta1 update-iam-policy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members` to a single `role`. Members can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. Optionally, a `binding` can specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": ["user:eve@example.com"], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') - etag: BwWWja0YfJA= - version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {bindings?: list, etag?: string, version?: int}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:setIamPolicy") $qp)
  let req_body = {"policy": $policy} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print} | compact), body: $req_body}
}

# Returns permissions that a caller has on the specified resource. If the resource does not exist, this will return an empty set of permissions, not a NOT_FOUND error. Note: This operation is designed to be used for building permission-aware UIs and command-line tools, not for authorization checking. This operation may "fail open" without warning.
#
# POST /v1beta1/{resource}:testIamPermissions
# operationId: servicebroker.testIamPermissions
export def "v1beta1 test-iam-permissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --fields: string # Selector specifying which fields to include in a partial response.
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --callback: string # JSONP
  --oauth-token: string # OAuth 2.0 token for the current user.
  --xgafv: string@xgafv-completer # V1 error format.
  --alt: string@alt-completer # Data format for response. (default: json)
  --access-token: string # OAuth access token.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks. (default: true)
  --permissions: list<string> # The set of permissions to check for the `resource`. Permissions with wildcards (such as '*' or 'storage.*') are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($resource | is-empty) { error make --unspanned { msg: "path parameter 'resource' must be non-empty" } }
  let qp = [(serialize-qp "fields" $fields "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: (encode-path-segment $resource)} | format pattern "/v1beta1/{resource}:testIamPermissions") $qp)
  let req_body = {"permissions": $permissions} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "*/*"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"fields": $fields, "uploadType": $upload_type, "callback": $callback, "oauth_token": $oauth_token, "$.xgafv": $xgafv, "alt": $alt, "access_token": $access_token, "key": $key, "upload_protocol": $upload_protocol, "quotaUser": $quota_user, "prettyPrint": $pretty_print} | compact), body: $req_body}
}
