# Auto-generated client for OS Config API vv1beta
# Source: https://api.apis.guru/v2/specs/googleapis.com/osconfig/v1beta/openapi.json
# Auth: --token flag or $env.OS_CONFIG_API_TOKEN

const BASE_URL = "https://osconfig.googleapis.com"
const DEFAULT_AUTH = "bearer"

# Build auth: returns {headers: record, query: string}
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o OS_CONFIG_API_TOKEN | default "" }
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

def base-url-completer [] { ["https://osconfig.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta osconfigprojectszonesinstanceslookupEffectiveGuestPolicy" } } | get name | first)
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

# Lookup the effective guest policy that applies to a VM instance. This lookup merges all policies that are assigned to the instance ancestry.
#
# POST /v1beta/{instance}:lookupEffectiveGuestPolicy
# operationId: osconfig.projects.zones.instances.lookupEffectiveGuestPolicy
export def "v1beta osconfigprojectszonesinstanceslookupEffectiveGuestPolicy" [
  instance: string
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
  --osArchitecture: string # Architecture of OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --osShortName: string # Short name of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --osVersion: string # Version of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that VM instance.
]: any -> record<packageRepositories: table<packageRepository: record, source: string>, packages: table<package: record, source: string>, softwareRecipes: table<softwareRecipe: record, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($instance):lookupEffectiveGuestPolicy" $qp)
  let body = {osArchitecture: $osArchitecture, osShortName: $osShortName, osVersion: $osVersion} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Delete an OS Config patch deployment.
#
# DELETE /v1beta/{name}
# operationId: osconfig.projects.patchDeployments.delete
export def "v1beta osconfigprojectspatchDeploymentsdelete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get the patch job. This can be used to track the progress of an ongoing patch job or review the details of completed jobs.
#
# GET /v1beta/{name}
# operationId: osconfig.projects.patchJobs.get
export def "v1beta osconfigprojectspatchJobsget" [
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
]: nothing -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name)" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Update an OS Config patch deployment.
#
# PATCH /v1beta/{name}
# operationId: osconfig.projects.patchDeployments.patch
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
# --oneTimeSchedule shape: {executeTime?: string}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --recurringSchedule shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta osconfigprojectspatchDeploymentspatch" [
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
  --updateMask: string # Optional. Field mask that controls which fields of the patch deployment should be updated.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instanceFilter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
  --body-name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment.
  --oneTimeSchedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patchConfig: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurringSchedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "updateMask" $updateMask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name)" $qp)
  let body = {description: $description, duration: $duration, instanceFilter: $instanceFilter, name: $body_name, oneTimeSchedule: $oneTimeSchedule, patchConfig: $patchConfig, recurringSchedule: $recurringSchedule, rollout: $rollout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Cancel a patch job. The patch job must be active. Canceled patch jobs cannot be restarted.
#
# POST /v1beta/{name}:cancel
# operationId: osconfig.projects.patchJobs.cancel
export def "v1beta osconfigprojectspatchJobscancel" [
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
  --body: record
]: any -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name):cancel" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change state of patch deployment to "PAUSED". Patch deployment in paused state doesn't generate patch jobs.
#
# POST /v1beta/{name}:pause
# operationId: osconfig.projects.patchDeployments.pause
export def "v1beta osconfigprojectspatchDeploymentspause" [
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
  --body: record
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name):pause" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Change state of patch deployment back to "ACTIVE". Patch deployment in active state continues to generate patch jobs.
#
# POST /v1beta/{name}:resume
# operationId: osconfig.projects.patchDeployments.resume
export def "v1beta osconfigprojectspatchDeploymentsresume" [
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
  --body: record
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($name):resume" $qp)
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a page of OS Config guest policies.
#
# GET /v1beta/{parent}/guestPolicies
# operationId: osconfig.projects.guestPolicies.list
export def "v1beta-guest-policies osconfigprojectsguestPolicieslist" [
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
  --pageSize: int # The maximum number of guest policies to return.
  --pageToken: string # A pagination token returned from a previous call to `ListGuestPolicies` that indicates where this listing should continue from.
]: nothing -> record<guestPolicies: table<assignment: record, createTime: string, description: string, etag: string, name: string, packageRepositories: list, packages: list, recipes: list, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/guestPolicies" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an OS Config guest policy.
#
# POST /v1beta/{parent}/guestPolicies
# operationId: osconfig.projects.guestPolicies.create
# --assignment shape: {groupLabels?: list, instanceNamePrefixes?: list, instances?: list, osTypes?: list, zones?: list}
# --packageRepositories item shape: {apt?: record, goo?: record, yum?: record, zypper?: record}
# --packages item shape: {desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", manager?: "MANAGER_UNSPECIFIED"|"ANY"|"APT"|"YUM"|"ZYPPER"|"GOO", name?: string}
# --recipes item shape: {artifacts?: list, desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", installSteps?: list, name?: string, updateSteps?: list, version?: string}
export def "v1beta-guest-policies osconfigprojectsguestPoliciescreate" [
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
  --guestPolicyId: string # Required. The logical name of the guest policy in the project with the following restrictions: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --assignment: record # An assignment represents the group or groups of VM instances that the policy applies to. If an assignment is empty, it applies to all VM instances. Otherwise, the targeted VM instances must meet all the criteria specified. So if both labels and zones are specified, the policy applies to VM instances with those labels and in those zones. — shape: {groupLabels?: list, instanceNamePrefixes?: list, instances?: list, osTypes?: list, zones?: list}
  --description: string # Description of the guest policy. Length of the description is limited to 1024 characters.
  --etag: string # The etag for this guest policy. If this is provided on update, it must match the server's etag.
  --name: string # Required. Unique name of the resource in this project using one of the following forms: `projects/{project_number}/guestPolicies/{guest_policy_id}`.
  --packageRepositories: list # A list of package repositories to configure on the VM instance. This is done before any other configs are applied so they can use these repos. Package repositories are only configured if the corresponding package manager(s) are available. — item shape: {apt?: record, goo?: record, yum?: record, zypper?: record}
  --packages: list # The software packages to be managed by this policy. — item shape: {desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", manager?: "MANAGER_UNSPECIFIED"|"ANY"|"APT"|"YUM"|"ZYPPER"|"GOO", name?: string}
  --recipes: list # A list of Recipes to install on the VM instance. — item shape: {artifacts?: list, desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", installSteps?: list, name?: string, updateSteps?: list, version?: string}
]: any -> record<assignment: record<groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, osTypes: list<record>, zones: list<string>>, createTime: string, description: string, etag: string, name: string, packageRepositories: table<apt: record, goo: record, yum: record, zypper: record>, packages: table<desiredState: string, manager: string, name: string>, recipes: table<artifacts: list, desiredState: string, installSteps: list, name: string, updateSteps: list, version: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "guestPolicyId" $guestPolicyId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/guestPolicies" $qp)
  let body = {assignment: $assignment, description: $description, etag: $etag, name: $name, packageRepositories: $packageRepositories, packages: $packages, recipes: $recipes} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of instance details for a given patch job.
#
# GET /v1beta/{parent}/instanceDetails
# operationId: osconfig.projects.patchJobs.instanceDetails.list
export def "v1beta-instance-details osconfigprojectspatchJobsinstanceDetailslist" [
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
  --filter: string # A filter expression that filters results listed in the response. This field supports filtering results by instance zone, name, state, or `failure_reason`.
  --pageSize: int # The maximum number of instance details records to return. Default is 100.
  --pageToken: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchJobInstanceDetails: table<attemptCount: string, failureReason: string, instanceSystemId: string, name: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/instanceDetails" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Get a page of OS Config patch deployments.
#
# GET /v1beta/{parent}/patchDeployments
# operationId: osconfig.projects.patchDeployments.list
export def "v1beta-patch-deployments osconfigprojectspatchDeploymentslist" [
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
  --pageSize: int # Optional. The maximum number of patch deployments to return. Default is 100.
  --pageToken: string # Optional. A pagination token returned from a previous call to ListPatchDeployments that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchDeployments: table<createTime: string, description: string, duration: string, instanceFilter: record, lastExecuteTime: string, name: string, oneTimeSchedule: record, patchConfig: record, recurringSchedule: record, rollout: record, state: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/patchDeployments" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Create an OS Config patch deployment.
#
# POST /v1beta/{parent}/patchDeployments
# operationId: osconfig.projects.patchDeployments.create
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
# --oneTimeSchedule shape: {executeTime?: string}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --recurringSchedule shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta-patch-deployments osconfigprojectspatchDeploymentscreate" [
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
  --patchDeploymentId: string # Required. A name for the patch deployment in the project. When creating a name the following rules apply: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instanceFilter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
  --name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment.
  --oneTimeSchedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patchConfig: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurringSchedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "patchDeploymentId" $patchDeploymentId "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/patchDeployments" $qp)
  let body = {description: $description, duration: $duration, instanceFilter: $instanceFilter, name: $name, oneTimeSchedule: $oneTimeSchedule, patchConfig: $patchConfig, recurringSchedule: $recurringSchedule, rollout: $rollout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}

# Get a list of patch jobs.
#
# GET /v1beta/{parent}/patchJobs
# operationId: osconfig.projects.patchJobs.list
export def "v1beta-patch-jobs osconfigprojectspatchJobslist" [
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
  --filter: string # If provided, this field specifies the criteria that must be met by patch jobs to be included in the response. Currently, filtering is only available on the patch_deployment field.
  --pageSize: int # The maximum number of instance status to return.
  --pageToken: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchJobs: table<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record, instanceFilter: record, name: string, patchConfig: record, patchDeployment: string, percentComplete: float, rollout: record, state: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $pageSize "scalar") (serialize-qp "pageToken" $pageToken "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/patchJobs" $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json"
}

# Patch VM instances by creating and running a patch job.
#
# POST /v1beta/{parent}/patchJobs:execute
# operationId: osconfig.projects.patchJobs.execute
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta-patch-jobs-execute osconfigprojectspatchJobsexecute" [
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
  --description: string # Description of the patch job. Length of the description is limited to 1024 characters.
  --displayName: string # Display name for this patch job. This does not have to be unique.
  --dryRun: oneof<nothing, bool> # If this patch is a dry-run only, instances are contacted but will do nothing.
  --duration: string # Duration of the patch job. After the duration ends, the patch job times out. (format: google-duration)
  --instanceFilter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list, instances?: list, zones?: list}
  --patchConfig: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $qp_fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $prettyPrint "scalar") (serialize-qp "quotaUser" $quotaUser "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $uploadType "scalar")] | flatten | str join "&"
  let full_url = (build-url $base $"/v1beta/($parent)/patchJobs:execute" $qp)
  let body = {description: $description, displayName: $displayName, dryRun: $dryRun, duration: $duration, instanceFilter: $instanceFilter, patchConfig: $patchConfig, rollout: $rollout} | compact
  let body = if ($input | describe | str starts-with "record") { $input | merge deep ($body | default {}) } else { $body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors "application/json" $body
}
