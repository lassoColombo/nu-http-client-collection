# Auto-generated client for Assured Workloads API vv1beta1
# Source: https://api.apis.guru/v2/specs/googleapis.com/assuredworkloads/v1beta1/openapi.json
# Auth: --token flag or $env.ASSURED_WORKLOADS_API_TOKEN

const BASE_URL = "https://assuredworkloads.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o ASSURED_WORKLOADS_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://assuredworkloads.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }
def complianceRegime-completer [] { ["ASSURED_WORKLOADS_FOR_PARTNERS" "AU_REGIONS_AND_US_SUPPORT" "CA_PROTECTED_B" "CA_REGIONS_AND_SUPPORT" "CJIS" "COMPLIANCE_REGIME_UNSPECIFIED" "EU_REGIONS_AND_SUPPORT" "FEDRAMP_HIGH" "FEDRAMP_MODERATE" "HIPAA" "HITRUST" "IL4" "ISR_REGIONS" "ISR_REGIONS_AND_SUPPORT" "ITAR" "US_REGIONAL_ACCESS"] }
def partner-completer [] { ["LOCAL_CONTROLS_BY_S3NS" "PARTNER_UNSPECIFIED" "SOVEREIGN_CONTROLS_BY_PSN" "SOVEREIGN_CONTROLS_BY_SIA_MINSAIT" "SOVEREIGN_CONTROLS_BY_T_SYSTEMS"] }
def restrictionType-completer [] { ["ALLOW_ALL_GCP_RESOURCES" "ALLOW_COMPLIANT_RESOURCES" "APPEND_COMPLIANT_RESOURCES" "RESTRICTION_TYPE_UNSPECIFIED"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta1 assuredworkloadsorganizationslocationsworkloadsdelete" } } | get name | first)
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

# Deletes the workload. Make sure that workload's direct children are already in a deleted state, otherwise the request will fail with a FAILED_PRECONDITION error. In addition to assuredworkloads.workload.delete permission, the user should also have orgpolicy.policy.set permission on the deleted folder to remove Assured Workloads OrgPolicies.
#
# DELETE /v1beta1/{name}
# operationId: assuredworkloads.organizations.locations.workloads.delete
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadsdelete" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --etag: string # Optional. The etag of the workload. If this is provided, it must match the server's etag.
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "etag" $etag "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Retrieves Assured Workload Violation based on ID.
#
# GET /v1beta1/{name}
# operationId: assuredworkloads.organizations.locations.workloads.violations.get
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadsviolationsget" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
]: nothing -> record<acknowledged: bool, acknowledgementTime: string, auditLogLink: string, beginTime: string, category: string, description: string, exceptionAuditLogLink: string, exceptionContexts: table<acknowledgementTime: string, comment: string, principalEmail: string>, name: string, nonCompliantOrgPolicy: string, orgPolicyConstraint: string, remediation: record<compliantValues: list<string>, instructions: record<consoleInstructions: record, gcloudInstructions: record>, remediationType: string>, resolveTime: string, state: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Updates an existing workload. Currently allows updating of workload display_name and labels. For force updates don't set etag field in the Workload. Only one update operation per workload can be in progress.
#
# PATCH /v1beta1/{name}
# operationId: assuredworkloads.organizations.locations.workloads.patch
# --cjisSettings shape: {kmsSettings?: record}
# --complianceStatus shape: {acknowledgedViolationCount?: int, activeViolationCount?: int}
# --ekmProvisioningResponse shape: {ekmProvisioningErrorDomain?: "EKM_PROVISIONING_ERROR_DOMAIN_UNSPECIFIED"|"UNSPECIFIED_ERROR"|"GOOGLE_SERVER_ERROR"|"EXTERNAL_USER_ERROR"|"EXTERNAL_PARTNER_ERROR"|"TIMEOUT_ERROR", ekmProvisioningErrorMapping?: "EKM_PROVISIONING_ERROR_MAPPING_UNSPECIFIED"|"INVALID_SERVICE_ACCOUNT"|"MISSING_METRICS_SCOPE_ADMIN_PERMISSION"|"MISSING_EKM_CONNECTION_ADMIN_PERMISSION", ekmProvisioningState?: "EKM_PROVISIONING_STATE_UNSPECIFIED"|"EKM_PROVISIONING_STATE_PENDING"|"EKM_PROVISIONING_STATE_FAILED"|"EKM_PROVISIONING_STATE_COMPLETED"}
# --fedrampHighSettings shape: {kmsSettings?: record}
# --fedrampModerateSettings shape: {kmsSettings?: record}
# --il4Settings shape: {kmsSettings?: record}
# --kmsSettings shape: {nextRotationTime?: string, rotationPeriod?: string}
# --resourceSettings item shape: {displayName?: string, resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
# --resources item shape: {resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
# --saaEnrollmentResponse shape: {setupErrors?: list, setupStatus?: "SETUP_STATE_UNSPECIFIED"|"STATUS_PENDING"|"STATUS_COMPLETE"}
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadspatch" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --updateMask: string # Required. The list of fields to be updated.
  --billingAccount: string # Optional. The billing account used for the resources which are direct children of workload. This billing account is initially associated with the resources created as part of Workload creation. After the initial creation of these resources, the customer can change the assigned billing account. The resource name has the form `billingAccounts/{billing_account_id}`. For example, `billingAccounts/012345-567890-ABCDEF`.
  --cjisSettings: record # Settings specific to resources needed for CJIS. — shape: {kmsSettings?: record}
  --complianceRegime: string@complianceRegime-completer # Required. Immutable. Compliance Regime associated with this workload.
  --complianceStatus: record # Represents the Compliance Status of this workload — shape: {acknowledgedViolationCount?: int, activeViolationCount?: int}
  --displayName: string # Required. The user-assigned display name of the Workload. When present it must be between 4 to 30 characters. Allowed characters are: lowercase and uppercase letters, numbers, hyphen, and spaces. Example: My Workload
  --ekmProvisioningResponse: record # External key management systems(EKM) Provisioning response — shape: {ekmProvisioningErrorDomain?: "EKM_PROVISIONING_ERROR_DOMAIN_UNSPECIFIED"|"UNSPECIFIED_ERROR"|"GOOGLE_SERVER_ERROR"|"EXTERNAL_USER_ERROR"|"EXTERNAL_PARTNER_ERROR"|"TIMEOUT_ERROR", ekmProvisioningErrorMapping?: "EKM_PROVISIONING_ERROR_MAPPING_UNSPECIFIED"|"INVALID_SERVICE_ACCOUNT"|"MISSING_METRICS_SCOPE_ADMIN_PERMISSION"|"MISSING_EKM_CONNECTION_ADMIN_PERMISSION", ekmProvisioningState?: "EKM_PROVISIONING_STATE_UNSPECIFIED"|"EKM_PROVISIONING_STATE_PENDING"|"EKM_PROVISIONING_STATE_FAILED"|"EKM_PROVISIONING_STATE_COMPLETED"}
  --enableSovereignControls: oneof<nothing, bool> # Optional. Indicates the sovereignty status of the given workload. Currently meant to be used by Europe/Canada customers.
  --etag: string # Optional. ETag of the workload, it is calculated on the basis of the Workload contents. It will be used in Update & Delete operations.
  --fedrampHighSettings: record # Settings specific to resources needed for FedRAMP High. — shape: {kmsSettings?: record}
  --fedrampModerateSettings: record # Settings specific to resources needed for FedRAMP Moderate. — shape: {kmsSettings?: record}
  --il4Settings: record # Settings specific to resources needed for IL4. — shape: {kmsSettings?: record}
  --kmsSettings: record # Settings specific to the Key Management Service. — shape: {nextRotationTime?: string, rotationPeriod?: string}
  --labels: record # Optional. Labels applied to the workload.
  --body-name: string # Optional. The resource name of the workload. Format: organizations/{organization}/locations/{location}/workloads/{workload} Read-only.
  --partner: string@partner-completer # Optional. Partner regime associated with this workload.
  --provisionedResourcesParent: string # Input only. The parent resource for the resources managed by this Assured Workload. May be either empty or a folder resource which is a child of the Workload parent. If not specified all resources are created under the parent organization. Format: folders/{folder_id}
  --resourceSettings: list # Input only. Resource properties that are used to customize workload resources. These properties (such as custom project id) will be used to create workload resources if possible. This field is optional. — item shape: {displayName?: string, resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
  --saaEnrollmentResponse: record # Signed Access Approvals (SAA) enrollment response. — shape: {setupErrors?: list, setupStatus?: "SETUP_STATE_UNSPECIFIED"|"STATUS_PENDING"|"STATUS_COMPLETE"}
  --violationNotificationsEnabled: oneof<nothing, bool> # Optional. Indicates whether the e-mail notification for a violation is enabled for a workload. This value will be by default True, and if not present will be considered as true. This should only be updated via updateWorkload call. Any Changes to this field during the createWorkload call will not be honored. This will always be true while creating the workload.
]: any -> record<billingAccount: string, cjisSettings: record<kmsSettings: record<nextRotationTime: string, rotationPeriod: string>>, complianceRegime: string, complianceStatus: record<acknowledgedViolationCount: int, activeViolationCount: int>, compliantButDisallowedServices: list<string>, createTime: string, displayName: string, ekmProvisioningResponse: record<ekmProvisioningErrorDomain: string, ekmProvisioningErrorMapping: string, ekmProvisioningState: string>, enableSovereignControls: bool, etag: string, fedrampHighSettings: record<kmsSettings: record<nextRotationTime: string, rotationPeriod: string>>, fedrampModerateSettings: record<kmsSettings: record<nextRotationTime: string, rotationPeriod: string>>, il4Settings: record<kmsSettings: record<nextRotationTime: string, rotationPeriod: string>>, kajEnrollmentState: string, kmsSettings: record<nextRotationTime: string, rotationPeriod: string>, labels: record, name: string, partner: string, provisionedResourcesParent: string, resourceSettings: table<displayName: string, resourceId: string, resourceType: string>, resources: table<resourceId: string, resourceType: string>, saaEnrollmentResponse: record<setupErrors: list<string>, setupStatus: string>, violationNotificationsEnabled: bool> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)" $qp)
  let body = {billingAccount: $billingAccount, cjisSettings: $cjisSettings, complianceRegime: $complianceRegime, complianceStatus: $complianceStatus, displayName: $displayName, ekmProvisioningResponse: $ekmProvisioningResponse, enableSovereignControls: $enableSovereignControls, etag: $etag, fedrampHighSettings: $fedrampHighSettings, fedrampModerateSettings: $fedrampModerateSettings, il4Settings: $il4Settings, kmsSettings: $kmsSettings, labels: $labels, name: $body_name, partner: $partner, provisionedResourcesParent: $provisionedResourcesParent, resourceSettings: $resourceSettings, saaEnrollmentResponse: $saaEnrollmentResponse, violationNotificationsEnabled: $violationNotificationsEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists operations that match the specified filter in the request. If the server doesn't support this method, it returns `UNIMPLEMENTED`.
#
# GET /v1beta1/{name}/operations
# operationId: assuredworkloads.organizations.locations.operations.list
export def "v1beta1-operations assuredworkloadsorganizationslocationsoperationslist" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # The standard list filter.
  --pageSize: int # The standard list page size.
  --pageToken: string # The standard list page token.
]: nothing -> record<nextPageToken: string, operations: table<done: bool, error: record, metadata: record, name: string, response: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name)/operations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Acknowledges an existing violation. By acknowledging a violation, users acknowledge the existence of a compliance violation in their workload and decide to ignore it due to a valid business justification. Acknowledgement is a permanent operation and it cannot be reverted.
#
# POST /v1beta1/{name}:acknowledge
# operationId: assuredworkloads.organizations.locations.workloads.violations.acknowledge
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadsviolationsacknowledge" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --comment: string # Required. Business justification explaining the need for violation acknowledgement
  --nonCompliantOrgPolicy: string # Optional. This field is deprecated and will be removed in future version of the API. Name of the OrgPolicy which was modified with non-compliant change and resulted in this violation. Format: projects/{project_number}/policies/{constraint_name} folders/{folder_id}/policies/{constraint_name} organizations/{organization_id}/policies/{constraint_name}
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name):acknowledge" $qp)
  let body = {comment: $comment, nonCompliantOrgPolicy: $nonCompliantOrgPolicy} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Restrict the list of resources allowed in the Workload environment. The current list of allowed products can be found at https://cloud.google.com/assured-workloads/docs/supported-products In addition to assuredworkloads.workload.update permission, the user should also have orgpolicy.policy.set permission on the folder resource to use this functionality.
#
# POST /v1beta1/{name}:restrictAllowedResources
# operationId: assuredworkloads.organizations.locations.workloads.restrictAllowedResources
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadsrestrictAllowedResources" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --restrictionType: string@restrictionType-completer # Required. The type of restriction for using gcp products in the Workload environment.
]: any -> record {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($name):restrictAllowedResources" $qp)
  let body = {restrictionType: $restrictionType} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Lists the Violations in the AssuredWorkload Environment. Callers may also choose to read across multiple Workloads as per [AIP-159](https://google.aip.dev/159) by using '-' (the hyphen or dash character) as a wildcard character instead of workload-id in the parent. Format `organizations/{org_id}/locations/{location}/workloads/-`
#
# GET /v1beta1/{parent}/violations
# operationId: assuredworkloads.organizations.locations.workloads.violations.list
export def "v1beta1-violations assuredworkloadsorganizationslocationsworkloadsviolationslist" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # Optional. A custom filter for filtering by the Violations properties.
  --intervalendTime: string # The end of the time window.
  --intervalstartTime: string # The start of the time window.
  --pageSize: int # Optional. Page size.
  --pageToken: string # Optional. Page token returned from previous request.
]: nothing -> record<nextPageToken: string, violations: table<acknowledged: bool, acknowledgementTime: string, auditLogLink: string, beginTime: string, category: string, description: string, exceptionAuditLogLink: string, exceptionContexts: list, name: string, nonCompliantOrgPolicy: string, orgPolicyConstraint: string, remediation: record, resolveTime: string, state: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "interval.endTime" $intervalendTime "scalar") (serialize-qp "interval.startTime" $intervalstartTime "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/violations" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Lists Assured Workloads under a CRM Node.
#
# GET /v1beta1/{parent}/workloads
# operationId: assuredworkloads.organizations.locations.workloads.list
export def "v1beta1-workloads assuredworkloadsorganizationslocationsworkloadslist" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --filter: string # A custom filter for filtering by properties of a workload. At this time, only filtering by labels is supported.
  --pageSize: int # Page size.
  --pageToken: string # Page token returned from previous request. Page token contains context from previous request. Page token needs to be passed in the second and following requests.
]: nothing -> record<nextPageToken: string, workloads: table<billingAccount: string, cjisSettings: record, complianceRegime: string, complianceStatus: record, compliantButDisallowedServices: list, createTime: string, displayName: string, ekmProvisioningResponse: record, enableSovereignControls: bool, etag: string, fedrampHighSettings: record, fedrampModerateSettings: record, il4Settings: record, kajEnrollmentState: string, kmsSettings: record, labels: record, name: string, partner: string, provisionedResourcesParent: string, resourceSettings: list, resources: list, saaEnrollmentResponse: record, violationNotificationsEnabled: bool>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/workloads" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Creates Assured Workload.
#
# POST /v1beta1/{parent}/workloads
# operationId: assuredworkloads.organizations.locations.workloads.create
# --cjisSettings shape: {kmsSettings?: record}
# --complianceStatus shape: {acknowledgedViolationCount?: int, activeViolationCount?: int}
# --ekmProvisioningResponse shape: {ekmProvisioningErrorDomain?: "EKM_PROVISIONING_ERROR_DOMAIN_UNSPECIFIED"|"UNSPECIFIED_ERROR"|"GOOGLE_SERVER_ERROR"|"EXTERNAL_USER_ERROR"|"EXTERNAL_PARTNER_ERROR"|"TIMEOUT_ERROR", ekmProvisioningErrorMapping?: "EKM_PROVISIONING_ERROR_MAPPING_UNSPECIFIED"|"INVALID_SERVICE_ACCOUNT"|"MISSING_METRICS_SCOPE_ADMIN_PERMISSION"|"MISSING_EKM_CONNECTION_ADMIN_PERMISSION", ekmProvisioningState?: "EKM_PROVISIONING_STATE_UNSPECIFIED"|"EKM_PROVISIONING_STATE_PENDING"|"EKM_PROVISIONING_STATE_FAILED"|"EKM_PROVISIONING_STATE_COMPLETED"}
# --fedrampHighSettings shape: {kmsSettings?: record}
# --fedrampModerateSettings shape: {kmsSettings?: record}
# --il4Settings shape: {kmsSettings?: record}
# --kmsSettings shape: {nextRotationTime?: string, rotationPeriod?: string}
# --resourceSettings item shape: {displayName?: string, resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
# --resources item shape: {resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
# --saaEnrollmentResponse shape: {setupErrors?: list, setupStatus?: "SETUP_STATE_UNSPECIFIED"|"STATUS_PENDING"|"STATUS_COMPLETE"}
export def "v1beta1-workloads assuredworkloadsorganizationslocationsworkloadscreate" [
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --externalId: string # Optional. A identifier associated with the workload and underlying projects which allows for the break down of billing costs for a workload. The value provided for the identifier will add a label to the workload and contained projects with the identifier as the value.
  --billingAccount: string # Optional. The billing account used for the resources which are direct children of workload. This billing account is initially associated with the resources created as part of Workload creation. After the initial creation of these resources, the customer can change the assigned billing account. The resource name has the form `billingAccounts/{billing_account_id}`. For example, `billingAccounts/012345-567890-ABCDEF`.
  --cjisSettings: record # Settings specific to resources needed for CJIS. — shape: {kmsSettings?: record}
  --complianceRegime: string@complianceRegime-completer # Required. Immutable. Compliance Regime associated with this workload.
  --complianceStatus: record # Represents the Compliance Status of this workload — shape: {acknowledgedViolationCount?: int, activeViolationCount?: int}
  --displayName: string # Required. The user-assigned display name of the Workload. When present it must be between 4 to 30 characters. Allowed characters are: lowercase and uppercase letters, numbers, hyphen, and spaces. Example: My Workload
  --ekmProvisioningResponse: record # External key management systems(EKM) Provisioning response — shape: {ekmProvisioningErrorDomain?: "EKM_PROVISIONING_ERROR_DOMAIN_UNSPECIFIED"|"UNSPECIFIED_ERROR"|"GOOGLE_SERVER_ERROR"|"EXTERNAL_USER_ERROR"|"EXTERNAL_PARTNER_ERROR"|"TIMEOUT_ERROR", ekmProvisioningErrorMapping?: "EKM_PROVISIONING_ERROR_MAPPING_UNSPECIFIED"|"INVALID_SERVICE_ACCOUNT"|"MISSING_METRICS_SCOPE_ADMIN_PERMISSION"|"MISSING_EKM_CONNECTION_ADMIN_PERMISSION", ekmProvisioningState?: "EKM_PROVISIONING_STATE_UNSPECIFIED"|"EKM_PROVISIONING_STATE_PENDING"|"EKM_PROVISIONING_STATE_FAILED"|"EKM_PROVISIONING_STATE_COMPLETED"}
  --enableSovereignControls: oneof<nothing, bool> # Optional. Indicates the sovereignty status of the given workload. Currently meant to be used by Europe/Canada customers.
  --etag: string # Optional. ETag of the workload, it is calculated on the basis of the Workload contents. It will be used in Update & Delete operations.
  --fedrampHighSettings: record # Settings specific to resources needed for FedRAMP High. — shape: {kmsSettings?: record}
  --fedrampModerateSettings: record # Settings specific to resources needed for FedRAMP Moderate. — shape: {kmsSettings?: record}
  --il4Settings: record # Settings specific to resources needed for IL4. — shape: {kmsSettings?: record}
  --kmsSettings: record # Settings specific to the Key Management Service. — shape: {nextRotationTime?: string, rotationPeriod?: string}
  --labels: record # Optional. Labels applied to the workload.
  --name: string # Optional. The resource name of the workload. Format: organizations/{organization}/locations/{location}/workloads/{workload} Read-only.
  --partner: string@partner-completer # Optional. Partner regime associated with this workload.
  --provisionedResourcesParent: string # Input only. The parent resource for the resources managed by this Assured Workload. May be either empty or a folder resource which is a child of the Workload parent. If not specified all resources are created under the parent organization. Format: folders/{folder_id}
  --resourceSettings: list # Input only. Resource properties that are used to customize workload resources. These properties (such as custom project id) will be used to create workload resources if possible. This field is optional. — item shape: {displayName?: string, resourceId?: string, resourceType?: "RESOURCE_TYPE_UNSPECIFIED"|"CONSUMER_PROJECT"|"CONSUMER_FOLDER"|"ENCRYPTION_KEYS_PROJECT"|"KEYRING"}
  --saaEnrollmentResponse: record # Signed Access Approvals (SAA) enrollment response. — shape: {setupErrors?: list, setupStatus?: "SETUP_STATE_UNSPECIFIED"|"STATUS_PENDING"|"STATUS_COMPLETE"}
  --violationNotificationsEnabled: oneof<nothing, bool> # Optional. Indicates whether the e-mail notification for a violation is enabled for a workload. This value will be by default True, and if not present will be considered as true. This should only be updated via updateWorkload call. Any Changes to this field during the createWorkload call will not be honored. This will always be true while creating the workload.
]: any -> record<done: bool, error: record<code: int, details: list<record>, message: string>, metadata: record, name: string, response: record> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "externalId" $externalId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($parent)/workloads" $qp)
  let body = {billingAccount: $billingAccount, cjisSettings: $cjisSettings, complianceRegime: $complianceRegime, complianceStatus: $complianceStatus, displayName: $displayName, ekmProvisioningResponse: $ekmProvisioningResponse, enableSovereignControls: $enableSovereignControls, etag: $etag, fedrampHighSettings: $fedrampHighSettings, fedrampModerateSettings: $fedrampModerateSettings, il4Settings: $il4Settings, kmsSettings: $kmsSettings, labels: $labels, name: $name, partner: $partner, provisionedResourcesParent: $provisionedResourcesParent, resourceSettings: $resourceSettings, saaEnrollmentResponse: $saaEnrollmentResponse, violationNotificationsEnabled: $violationNotificationsEnabled} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Analyzes a hypothetical move of a source project or project-based workload to a target (destination) folder-based workload.
#
# GET /v1beta1/{project}/{target}:analyzeWorkloadMove
# operationId: assuredworkloads.projects.organizations.locations.workloads.analyzeWorkloadMove
export def "v1beta1 assuredworkloadsprojectsorganizationslocationsworkloadsanalyzeWorkloadMove" [
  project: string
  target: string
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --qp-source: string # The source type is a project-based workload. Specify the workloads's relative resource name, formatted as: "organizations/{ORGANIZATION_ID}/locations/{LOCATION_ID}/workloads/{WORKLOAD_ID}" For example: "organizations/123/locations/us-east1/workloads/assured-workload-1"
]: nothing -> record<blockers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "source" $qp_source "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($project)/($target):analyzeWorkloadMove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Analyzes a hypothetical move of a source project or project-based workload to a target (destination) folder-based workload.
#
# GET /v1beta1/{source}/{target}:analyzeWorkloadMove
# operationId: assuredworkloads.organizations.locations.workloads.organizations.locations.workloads.analyzeWorkloadMove
export def "v1beta1 assuredworkloadsorganizationslocationsworkloadsorganizationslocationsworkloadsanalyzeWorkloadMove" [
  source: string
  target: string
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
  --qp-fields: string # Selector specifying which fields to include in a partial response.
  --key: string # API key. Your API key identifies your project and provides you with API access, quota, and reports. Required unless you provide an OAuth 2.0 token.
  --oauth-token: string # OAuth 2.0 token for the current user.
  --prettyPrint: oneof<nothing, bool> # Returns response with indentations and line breaks.
  --quotaUser: string # Available to use for quota purposes for server-side applications. Can be any arbitrary string assigned to a user, but should not exceed 40 characters.
  --upload-protocol: string # Upload protocol for media (e.g. "raw", "multipart").
  --uploadType: string # Legacy upload protocol for media (e.g. "media", "multipart").
  --project: string # The source type is a project. Specify the project's relative resource name, formatted as either a project number or a project ID: "projects/{PROJECT_NUMBER}" or "projects/{PROJECT_ID}" For example: "projects/951040570662" when specifying a project number, or "projects/my-project-123" when specifying a project ID.
]: nothing -> record<blockers: list<string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "project" $project "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta1/($source)/($target):analyzeWorkloadMove" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}
