# Auto-generated client for Cloud Run Admin API vv2
# Source: https://api.apis.guru/v2/specs/googleapis.com/run/v2/openapi.json
# Auth: --token flag or $env.CLOUD_RUN_ADMIN_API_TOKEN

const BASE_URL = "https://run.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o CLOUD_RUN_ADMIN_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://run.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def ingress-completer [] { ["INGRESS_TRAFFIC_ALL" "INGRESS_TRAFFIC_INTERNAL_LOAD_BALANCER" "INGRESS_TRAFFIC_INTERNAL_ONLY" "INGRESS_TRAFFIC_UNSPECIFIED"] }
def launch-stage-completer [] { ["ALPHA" "BETA" "DEPRECATED" "EARLY_ACCESS" "GA" "LAUNCH_STAGE_UNSPECIFIED" "PRELAUNCH" "UNIMPLEMENTED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "projects runprojectslocationsservicesrevisionsdelete" } } | get name | first)
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

# Deletes a Revision.
#
# DELETE /v2/{name}
# operationId: run.projects.locations.services.revisions.delete
export def "projects runprojectslocationsservicesrevisionsdelete" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --etag: string # A system-generated fingerprint for this version of the resource. This may be used to detect modification conflict during updates.
  --validate-only: oneof<nothing, bool> # Indicates that the request should be validated without actually deleting any resources.
]: nothing -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "etag" $etag "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets information about a Revision.
#
# GET /v2/{name}
# operationId: run.projects.locations.services.revisions.get
export def "projects runprojectslocationsservicesrevisionsget" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<annotations: record, conditions: table<executionReason: string, lastTransitionTime: string, message: string, reason: string, revisionReason: string, severity: string, state: string, type: string>, containers: table<args: list, command: list, env: list, image: string, livenessProbe: record, name: string, ports: list, resources: record, startupProbe: record, volumeMounts: list, workingDir: string>, createTime: string, deleteTime: string, encryptionKey: string, encryptionKeyRevocationAction: string, encryptionKeyShutdownDuration: string, etag: string, executionEnvironment: string, expireTime: string, generation: string, labels: record, launchStage: string, logUri: string, maxInstanceRequestConcurrency: int, name: string, observedGeneration: string, reconciling: bool, satisfiesPzs: bool, scaling: record<maxInstanceCount: int, minInstanceCount: int>, service: string, serviceAccount: string, timeout: string, uid: string, updateTime: string, volumes: table<cloudSqlInstance: record, name: string, secret: record>, vpcAccess: record<connector: string, egress: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates a Service.
#
# PATCH /v2/{name}
# operationId: run.projects.locations.services.patch
# --binaryAuthorization shape: {breakglassJustification?: string, useDefault?: bool}
# --conditions item shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
# --template shape: {annotations?: record, containers?: list, encryptionKey?: string, executionEnvironment?: "EXECUTION_ENVIRONMENT_UNSPECIFIED"|"EXECUTION_ENVIRONMENT_GEN1"|"EXECUTION_ENVIRONMENT_GEN2", labels?: record, maxInstanceRequestConcurrency?: int, revision?: string, scaling?: record, serviceAccount?: string, timeout?: string, volumes?: list, vpcAccess?: record}
# --terminalCondition shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
# --traffic item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"}
# --trafficStatuses item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", uri?: string}
export def "projects runprojectslocationsservicespatch" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --allow-missing: oneof<nothing, bool> # This field is currently not used by Cloud Run; setting it does not have any effect.
  --validate-only: oneof<nothing, bool> # Indicates that the request should be validated and default values populated, without persisting the request or updating any resources.
  --annotations: record # Unstructured key value map that may be set by external tools to store and arbitrary metadata. They are not queryable and should be preserved when modifying objects. Cloud Run API v2 does not support annotations with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected in new resources. All system annotations in v1 now have a corresponding field in v2 Service. This field follows Kubernetes annotations' namespacing, limits, and rules.
  --binary-authorization: record # Settings for Binary Authorization feature. — shape: {breakglassJustification?: string, useDefault?: bool}
  --client: string # Arbitrary identifier for the API client.
  --client-version: string # Arbitrary version identifier for the API client.
  --description: string # User-provided description of the Service. This field currently has a 512-character limit.
  --ingress: string@ingress-completer # Provides the ingress settings for this Service. On output, returns the currently observed ingress settings, or INGRESS_TRAFFIC_UNSPECIFIED if no revision is active.
  --labels: record # Map of string keys and values that can be used to organize and categorize objects. User-provided labels are shared with Google's billing system, so they can be used to filter, or break down billing charges by team, component, environment, state, etc. For more information, visit https://cloud.google.com/resource-manager/docs/creating-managing-labels or https://cloud.google.com/run/docs/configuring/labels Cloud Run API v2 does not support labels with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected. All system labels in v1 now have a corresponding field in v2 Service.
  --launch-stage: string@launch-stage-completer # The launch stage as defined by [Google Cloud Platform Launch Stages](https://cloud.google.com/terms/launch-stages). Cloud Run supports `ALPHA`, `BETA`, and `GA`. If no value is specified, GA is assumed. Set the launch stage to a preview stage on input to allow use of preview features in that stage. On read (or output), describes whether the resource uses preview features. For example, if ALPHA is provided as input, but only BETA and GA-level features are used, this field will be BETA on output.
  --body-name: string # The fully qualified name of this Service. In CreateServiceRequest, this field is ignored, and instead composed from CreateServiceRequest.parent and CreateServiceRequest.service_id. Format: projects/{project}/locations/{location}/services/{service_id}
  --template: record # RevisionTemplate describes the data a revision should have when created from a template. — shape: {annotations?: record, containers?: list, encryptionKey?: string, executionEnvironment?: "EXECUTION_ENVIRONMENT_UNSPECIFIED"|"EXECUTION_ENVIRONMENT_GEN1"|"EXECUTION_ENVIRONMENT_GEN2", labels?: record, maxInstanceRequestConcurrency?: int, revision?: string, scaling?: record, serviceAccount?: string, timeout?: string, volumes?: list, vpcAccess?: record}
  --terminal-condition: record # Defines a status condition for a resource. — shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
  --traffic: list # Specifies how to distribute traffic over a collection of Revisions belonging to the Service. If traffic is empty or not provided, defaults to 100% traffic to the latest `Ready` Revision. — item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "allowMissing" $allow_missing "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}") $qp)
  let body = {"annotations": $annotations, "binaryAuthorization": $binary_authorization, "client": $client, "clientVersion": $client_version, "description": $description, "ingress": $ingress, "labels": $labels, "launchStage": $launch_stage, "name": $body_name, "template": $template, "terminalCondition": $terminal_condition, "traffic": $traffic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v2/{name}/operations
# operationId: run.projects.locations.operations.list
export def "operations runprojectslocationsoperationslist" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. A filter for matching the completed or in-progress operations. The supported formats of *filter* are: To query for only completed operations: done:true To query for only ongoing operations: done:false Must be empty to query for all of the latest operations for the given parent project.
  --page-size: int # The maximum number of records that should be returned. Requested page size cannot exceed 100. If not set or set to less than or equal to 0, the default page size is 100. .
  --page-token: string # Token identifying which result to start with, which is returned by a previous list call.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Triggers creation of a new Execution of this Job.
#
# POST /v2/{name}:run
# operationId: run.projects.locations.jobs.run
export def "projects runprojectslocationsjobsrun" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --etag: string # A system-generated fingerprint for this version of the resource. May be used to detect modification conflict during updates.
  --validate-only: oneof<nothing, bool> # Indicates that the request should be validated without actually deleting any resources.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}:run") $qp)
  let body = {"etag": $etag, "validateOnly": $validate_only} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Waits until the specified long-running operation is done or reaches at most a specified timeout, returning the latest state. If the operation is already done, the latest state is immediately returned. If the timeout specified is greater than the default HTTP/RPC timeout, the HTTP/RPC timeout is used. If the server does not support this method, it returns `google.rpc.Code.UNIMPLEMENTED`. Note that this method is on a best-effort basis. It may return the latest state before the specified timeout (including immediately), meaning even an immediate response is no guarantee that the operation is done.
#
# POST /v2/{name}:wait
# operationId: run.projects.locations.operations.wait
export def "projects runprojectslocationsoperationswait" [
  name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --timeout: string # The maximum duration to wait before timing out. If left blank, the wait will be at most the time permitted by the underlying HTTP/RPC protocol. If RPC context deadline is also specified, the shorter one will be used. (format: google-duration)
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: $name} | format pattern "/v2/{name}:wait") $qp)
  let body = {"timeout": $timeout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Executions from a Job.
#
# GET /v2/{parent}/executions
# operationId: run.projects.locations.jobs.executions.list
export def "executions runprojectslocationsjobsexecutionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Executions to return in this call.
  --page-token: string # A page token received from a previous call to ListExecutions. All other parameters must match.
  --show-deleted: oneof<nothing, bool> # If true, returns deleted (but unexpired) resources along with active ones.
]: nothing -> record<executions: table<annotations: record, cancelledCount: int, completionTime: string, conditions: list, createTime: string, deleteTime: string, etag: string, expireTime: string, failedCount: int, generation: string, job: string, labels: record, launchStage: string, logUri: string, name: string, observedGeneration: string, parallelism: int, reconciling: bool, retriedCount: int, runningCount: int, satisfiesPzs: bool, startTime: string, succeededCount: int, taskCount: int, template: record, uid: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/executions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Jobs.
#
# GET /v2/{parent}/jobs
# operationId: run.projects.locations.jobs.list
export def "jobs runprojectslocationsjobslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Jobs to return in this call.
  --page-token: string # A page token received from a previous call to ListJobs. All other parameters must match.
  --show-deleted: oneof<nothing, bool> # If true, returns deleted (but unexpired) resources along with active ones.
]: nothing -> record<jobs: table<annotations: record, binaryAuthorization: record, client: string, clientVersion: string, conditions: list, createTime: string, creator: string, deleteTime: string, etag: string, executionCount: int, expireTime: string, generation: string, labels: record, lastModifier: string, latestCreatedExecution: record, launchStage: string, name: string, observedGeneration: string, reconciling: bool, satisfiesPzs: bool, template: record, terminalCondition: record, uid: string, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/jobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a Job.
#
# POST /v2/{parent}/jobs
# operationId: run.projects.locations.jobs.create
# --binaryAuthorization shape: {breakglassJustification?: string, useDefault?: bool}
# --conditions item shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
# --latestCreatedExecution shape: {completionTime?: string, createTime?: string, name?: string}
# --template shape: {annotations?: record, labels?: record, parallelism?: int, taskCount?: int, template?: record}
# --terminalCondition shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
export def "jobs runprojectslocationsjobscreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --job-id: string # Required. The unique identifier for the Job. The name of the job becomes {parent}/jobs/{job_id}.
  --validate-only: oneof<nothing, bool> # Indicates that the request should be validated and default values populated, without persisting the request or creating any resources.
  --annotations: record # KRM-style annotations for the resource. Unstructured key value map that may be set by external tools to store and arbitrary metadata. They are not queryable and should be preserved when modifying objects. Cloud Run API v2 does not support annotations with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected on new resources. All system annotations in v1 now have a corresponding field in v2 Job. This field follows Kubernetes annotations' namespacing, limits, and rules.
  --binary-authorization: record # Settings for Binary Authorization feature. — shape: {breakglassJustification?: string, useDefault?: bool}
  --client: string # Arbitrary identifier for the API client.
  --client-version: string # Arbitrary version identifier for the API client.
  --labels: record # KRM-style labels for the resource. User-provided labels are shared with Google's billing system, so they can be used to filter, or break down billing charges by team, component, environment, state, etc. For more information, visit https://cloud.google.com/resource-manager/docs/creating-managing-labels or https://cloud.google.com/run/docs/configuring/labels Cloud Run API v2 does not support labels with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected. All system labels in v1 now have a corresponding field in v2 Job.
  --latest-created-execution: record # Reference to an Execution. Use /Executions.GetExecution with the given name to get full execution including the latest status. — shape: {completionTime?: string, createTime?: string, name?: string}
  --launch-stage: string@launch-stage-completer # The launch stage as defined by [Google Cloud Platform Launch Stages](https://cloud.google.com/terms/launch-stages). Cloud Run supports `ALPHA`, `BETA`, and `GA`. If no value is specified, GA is assumed. Set the launch stage to a preview stage on input to allow use of preview features in that stage. On read (or output), describes whether the resource uses preview features. For example, if ALPHA is provided as input, but only BETA and GA-level features are used, this field will be BETA on output.
  --name: string # The fully qualified name of this Job. Format: projects/{project}/locations/{location}/jobs/{job}
  --template: record # ExecutionTemplate describes the data an execution should have when created from a template. — shape: {annotations?: record, labels?: record, parallelism?: int, taskCount?: int, template?: record}
  --terminal-condition: record # Defines a status condition for a resource. — shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "jobId" $job_id "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/jobs") $qp)
  let body = {"annotations": $annotations, "binaryAuthorization": $binary_authorization, "client": $client, "clientVersion": $client_version, "labels": $labels, "latestCreatedExecution": $latest_created_execution, "launchStage": $launch_stage, "name": $name, "template": $template, "terminalCondition": $terminal_condition} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Revisions from a given Service, or from a given location.
#
# GET /v2/{parent}/revisions
# operationId: run.projects.locations.services.revisions.list
export def "revisions runprojectslocationsservicesrevisionslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of revisions to return in this call.
  --page-token: string # A page token received from a previous call to ListRevisions. All other parameters must match.
  --show-deleted: oneof<nothing, bool> # If true, returns deleted (but unexpired) resources along with active ones.
]: nothing -> record<nextPageToken: string, revisions: table<annotations: record, conditions: list, containers: list, createTime: string, deleteTime: string, encryptionKey: string, encryptionKeyRevocationAction: string, encryptionKeyShutdownDuration: string, etag: string, executionEnvironment: string, expireTime: string, generation: string, labels: record, launchStage: string, logUri: string, maxInstanceRequestConcurrency: int, name: string, observedGeneration: string, reconciling: bool, satisfiesPzs: bool, scaling: record, service: string, serviceAccount: string, timeout: string, uid: string, updateTime: string, volumes: list, vpcAccess: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/revisions") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Services.
#
# GET /v2/{parent}/services
# operationId: run.projects.locations.services.list
export def "services runprojectslocationsserviceslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Services to return in this call.
  --page-token: string # A page token received from a previous call to ListServices. All other parameters must match.
  --show-deleted: oneof<nothing, bool> # If true, returns deleted (but unexpired) resources along with active ones.
]: nothing -> record<nextPageToken: string, services: table<annotations: record, binaryAuthorization: record, client: string, clientVersion: string, conditions: list, createTime: string, creator: string, deleteTime: string, description: string, etag: string, expireTime: string, generation: string, ingress: string, labels: record, lastModifier: string, latestCreatedRevision: string, latestReadyRevision: string, launchStage: string, name: string, observedGeneration: string, reconciling: bool, satisfiesPzs: bool, template: record, terminalCondition: record, traffic: list, trafficStatuses: list, uid: string, updateTime: string, uri: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/services") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates a new Service in a given project and location.
#
# POST /v2/{parent}/services
# operationId: run.projects.locations.services.create
# --binaryAuthorization shape: {breakglassJustification?: string, useDefault?: bool}
# --conditions item shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
# --template shape: {annotations?: record, containers?: list, encryptionKey?: string, executionEnvironment?: "EXECUTION_ENVIRONMENT_UNSPECIFIED"|"EXECUTION_ENVIRONMENT_GEN1"|"EXECUTION_ENVIRONMENT_GEN2", labels?: record, maxInstanceRequestConcurrency?: int, revision?: string, scaling?: record, serviceAccount?: string, timeout?: string, volumes?: list, vpcAccess?: record}
# --terminalCondition shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
# --traffic item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"}
# --trafficStatuses item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION", uri?: string}
export def "services runprojectslocationsservicescreate" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --service-id: string # Required. The unique identifier for the Service. It must begin with letter, and cannot end with hyphen; must contain fewer than 50 characters. The name of the service becomes {parent}/services/{service_id}.
  --validate-only: oneof<nothing, bool> # Indicates that the request should be validated and default values populated, without persisting the request or creating any resources.
  --annotations: record # Unstructured key value map that may be set by external tools to store and arbitrary metadata. They are not queryable and should be preserved when modifying objects. Cloud Run API v2 does not support annotations with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected in new resources. All system annotations in v1 now have a corresponding field in v2 Service. This field follows Kubernetes annotations' namespacing, limits, and rules.
  --binary-authorization: record # Settings for Binary Authorization feature. — shape: {breakglassJustification?: string, useDefault?: bool}
  --client: string # Arbitrary identifier for the API client.
  --client-version: string # Arbitrary version identifier for the API client.
  --description: string # User-provided description of the Service. This field currently has a 512-character limit.
  --ingress: string@ingress-completer # Provides the ingress settings for this Service. On output, returns the currently observed ingress settings, or INGRESS_TRAFFIC_UNSPECIFIED if no revision is active.
  --labels: record # Map of string keys and values that can be used to organize and categorize objects. User-provided labels are shared with Google's billing system, so they can be used to filter, or break down billing charges by team, component, environment, state, etc. For more information, visit https://cloud.google.com/resource-manager/docs/creating-managing-labels or https://cloud.google.com/run/docs/configuring/labels Cloud Run API v2 does not support labels with `run.googleapis.com`, `cloud.googleapis.com`, `serving.knative.dev`, or `autoscaling.knative.dev` namespaces, and they will be rejected. All system labels in v1 now have a corresponding field in v2 Service.
  --launch-stage: string@launch-stage-completer # The launch stage as defined by [Google Cloud Platform Launch Stages](https://cloud.google.com/terms/launch-stages). Cloud Run supports `ALPHA`, `BETA`, and `GA`. If no value is specified, GA is assumed. Set the launch stage to a preview stage on input to allow use of preview features in that stage. On read (or output), describes whether the resource uses preview features. For example, if ALPHA is provided as input, but only BETA and GA-level features are used, this field will be BETA on output.
  --name: string # The fully qualified name of this Service. In CreateServiceRequest, this field is ignored, and instead composed from CreateServiceRequest.parent and CreateServiceRequest.service_id. Format: projects/{project}/locations/{location}/services/{service_id}
  --template: record # RevisionTemplate describes the data a revision should have when created from a template. — shape: {annotations?: record, containers?: list, encryptionKey?: string, executionEnvironment?: "EXECUTION_ENVIRONMENT_UNSPECIFIED"|"EXECUTION_ENVIRONMENT_GEN1"|"EXECUTION_ENVIRONMENT_GEN2", labels?: record, maxInstanceRequestConcurrency?: int, revision?: string, scaling?: record, serviceAccount?: string, timeout?: string, volumes?: list, vpcAccess?: record}
  --terminal-condition: record # Defines a status condition for a resource. — shape: {executionReason?: "EXECUTION_REASON_UNDEFINED"|"JOB_STATUS_SERVICE_POLLING_ERROR"|"NON_ZERO_EXIT_CODE"|"CANCELLED"|"CANCELLING", lastTransitionTime?: string, message?: string, reason?: "COMMON_REASON_UNDEFINED"|"UNKNOWN"|"REVISION_FAILED"|"PROGRESS_DEADLINE_EXCEEDED"|"CONTAINER_MISSING"|"CONTAINER_PERMISSION_DENIED"|"CONTAINER_IMAGE_UNAUTHORIZED"|"CONTAINER_IMAGE_AUTHORIZATION_CHECK_FAILED"|"ENCRYPTION_KEY_PERMISSION_DENIED"|"ENCRYPTION_KEY_CHECK_FAILED"|"SECRETS_ACCESS_CHECK_FAILED"|"WAITING_FOR_OPERATION"|"IMMEDIATE_RETRY"|"POSTPONED_RETRY"|"INTERNAL", revisionReason?: "REVISION_REASON_UNDEFINED"|"PENDING"|"RESERVE"|"RETIRED"|"RETIRING"|"RECREATING"|"HEALTH_CHECK_CONTAINER_ERROR"|"CUSTOMIZED_PATH_RESPONSE_PENDING"|"MIN_INSTANCES_NOT_PROVISIONED"|"ACTIVE_REVISION_LIMIT_REACHED"|"NO_DEPLOYMENT"|"HEALTH_CHECK_SKIPPED"|"MIN_INSTANCES_WARMING", severity?: "SEVERITY_UNSPECIFIED"|"ERROR"|"WARNING"|"INFO", state?: "STATE_UNSPECIFIED"|"CONDITION_PENDING"|"CONDITION_RECONCILING"|"CONDITION_FAILED"|"CONDITION_SUCCEEDED", type?: string}
  --traffic: list # Specifies how to distribute traffic over a collection of Revisions belonging to the Service. If traffic is empty or not provided, defaults to 100% traffic to the latest `Ready` Revision. — item shape: {percent?: int, revision?: string, tag?: string, type?: "TRAFFIC_TARGET_ALLOCATION_TYPE_UNSPECIFIED"|"TRAFFIC_TARGET_ALLOCATION_TYPE_LATEST"|"TRAFFIC_TARGET_ALLOCATION_TYPE_REVISION"}
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "serviceId" $service_id "scalar") (serialize-qp "validateOnly" $validate_only "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/services") $qp)
  let body = {"annotations": $annotations, "binaryAuthorization": $binary_authorization, "client": $client, "clientVersion": $client_version, "description": $description, "ingress": $ingress, "labels": $labels, "launchStage": $launch_stage, "name": $name, "template": $template, "terminalCondition": $terminal_condition, "traffic": $traffic} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists Tasks from an Execution of a Job.
#
# GET /v2/{parent}/tasks
# operationId: run.projects.locations.jobs.executions.tasks.list
export def "tasks runprojectslocationsjobsexecutionstaskslist" [
  parent: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --page-size: int # Maximum number of Tasks to return in this call.
  --page-token: string # A page token received from a previous call to ListTasks. All other parameters must match.
  --show-deleted: oneof<nothing, bool> # If true, returns deleted (but unexpired) resources along with active ones.
]: nothing -> record<nextPageToken: string, tasks: table<annotations: record, completionTime: string, conditions: list, containers: list, createTime: string, deleteTime: string, encryptionKey: string, etag: string, execution: string, executionEnvironment: string, expireTime: string, generation: string, index: int, job: string, labels: record, lastAttemptResult: record, logUri: string, maxRetries: int, name: string, observedGeneration: string, reconciling: bool, retried: int, satisfiesPzs: bool, serviceAccount: string, startTime: string, timeout: string, uid: string, updateTime: string, volumes: list, vpcAccess: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar") (serialize-qp "showDeleted" $show_deleted "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: $parent} | format pattern "/v2/{parent}/tasks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Gets the IAM Access Control policy currently in effect for the given Cloud Run Service. This result does not include any inherited policies.
#
# GET /v2/{resource}:getIamPolicy
# operationId: run.projects.locations.services.getIamPolicy
export def "projects runprojectslocationsservicesgetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --options-requested-policy-version: int # Optional. The maximum policy version that will be used to format the policy. Valid values are 0, 1, and 3. Requests specifying an invalid value will be rejected. Requests for policies with any conditional role bindings must specify version 3. Policies with no conditional role bindings may specify any valid value or leave the field unset. The policy in the response might use the policy version that you specified, or it might use a lower policy version. For example, if you specify version 3, but the policy has no conditional role bindings, the response uses version 1. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies).
]: nothing -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "options.requestedPolicyVersion" $options_requested_policy_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: $resource} | format pattern "/v2/{resource}:getIamPolicy") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Sets the IAM Access control policy for the specified Service. Overwrites any existing policy.
#
# POST /v2/{resource}:setIamPolicy
# operationId: run.projects.locations.services.setIamPolicy
# --policy shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
export def "projects runprojectslocationsservicessetIamPolicy" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --policy: record # An Identity and Access Management (IAM) policy, which specifies access controls for Google Cloud resources. A `Policy` is a collection of `bindings`. A `binding` binds one or more `members`, or principals, to a single `role`. Principals can be user accounts, service accounts, Google groups, and domains (such as G Suite). A `role` is a named list of permissions; each `role` can be an IAM predefined role or a user-created custom role. For some types of Google Cloud resources, a `binding` can also specify a `condition`, which is a logical expression that allows access to a resource only if the expression evaluates to `true`. A condition can add constraints based on attributes of the request, the resource, or both. To learn which resources support conditions in their IAM policies, see the [IAM documentation](https://cloud.google.com/iam/help/conditions/resource-policies). **JSON example:** { "bindings": [ { "role": "roles/resourcemanager.organizationAdmin", "members": [ "user:mike@example.com", "group:admins@example.com", "domain:google.com", "serviceAccount:my-project-id@appspot.gserviceaccount.com" ] }, { "role": "roles/resourcemanager.organizationViewer", "members": [ "user:eve@example.com" ], "condition": { "title": "expirable access", "description": "Does not grant access after Sep 2020", "expression": "request.time < timestamp('2020-10-01T00:00:00.000Z')", } } ], "etag": "BwWWja0YfJA=", "version": 3 } **YAML example:** bindings: - members: - user:mike@example.com - group:admins@example.com - domain:google.com - serviceAccount:my-project-id@appspot.gserviceaccount.com role: roles/resourcemanager.organizationAdmin - members: - user:eve@example.com role: roles/resourcemanager.organizationViewer condition: title: expirable access description: Does not grant access after Sep 2020 expression: request.time < timestamp('2020-10-01T00:00:00.000Z') etag: BwWWja0YfJA= version: 3 For a description of IAM and its features, see the [IAM documentation](https://cloud.google.com/iam/docs/). — shape: {auditConfigs?: list, bindings?: list, etag?: string, version?: int}
  --update-mask: string # OPTIONAL: A FieldMask specifying which fields of the policy to modify. Only the fields in the mask will be modified. If no mask is provided, the following default mask is used: `paths: "bindings, etag"` (format: google-fieldmask)
]: any -> record<auditConfigs: table<auditLogConfigs: list, service: string>, bindings: table<condition: record, members: list, role: string>, etag: string, version: int> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: $resource} | format pattern "/v2/{resource}:setIamPolicy") $qp)
  let body = {"policy": $policy, "updateMask": $update_mask} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Returns permissions that a caller has on the specified Project. There are no permissions required for making this API call.
#
# POST /v2/{resource}:testIamPermissions
# operationId: run.projects.locations.services.testIamPermissions
export def "projects runprojectslocationsservicestestIamPermissions" [
  resource: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --dry-run(-n) # Return the request that would be sent without executing it
  --xgafv: string@xgafv-completer # V1 error format.
  --access-token: string # OAuth access token.
  --alt: string@alt-completer # Data format for response.
  --callback: string # JSONP
  --fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --pretty-print: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quota-user: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --upload-type: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --permissions: list # The set of permissions to check for the `resource`. Permissions with wildcards (such as `*` or `storage.*`) are not allowed. For more information see [IAM Overview](https://cloud.google.com/iam/docs/overview#permissions).
]: any -> record<permissions: list<string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({resource: $resource} | format pattern "/v2/{resource}:testIamPermissions") $qp)
  let body = {"permissions": $permissions} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
