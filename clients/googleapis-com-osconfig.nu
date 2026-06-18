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
# Uses encode-path-segment for keys and values: RFC 3986 unreserved chars
# ([A-Za-z0-9-._~]) stay literal; everything else gets %XX.
def serialize-qp [name: string, value: any, style: string]: nothing -> list<string> {
  if ($value == null) { return [] }
  let n = (encode-path-segment $name)
  let is_list = ($value | describe | str starts-with "list")
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

# Execute HTTP request with method dispatch
def do-request [method: string, url: string, auth: record, insecure: bool, raw: bool, dry_run: bool, max_time?: duration, allow_errors?: bool, full?: bool, content_type?: string, body?: any]: nothing -> any {
  let req_url = if ($auth.query | is-not-empty) { if ($url | str contains "?") { $"($url)&($auth.query)" } else { $"($url)?($auth.query)" } } else { $url }
  let timeout = ($max_time | default 30min)
  let ct = ($content_type | default "application/json")
  if $dry_run { return {method: $method, url: $req_url, headers: $auth.headers, query_string: $auth.query, content_type: $ct, timeout: $timeout, body: $body} }
  let resp = match $method {
    "get" => { http get --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url }
    "head" => { http head --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "options" => { http options --headers $auth.headers --max-time $timeout --insecure=$insecure $req_url }
    "post" => { if ($body | is-empty) { http post --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http post --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "put" => { if ($body | is-empty) { http put --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http put --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "patch" => { if ($body | is-empty) { http patch --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url "" } else { http patch --headers $auth.headers --content-type $ct --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url $body } }
    "delete" => { if ($body | is-empty) { http delete --headers $auth.headers --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } else { http delete --headers $auth.headers --content-type $ct --data $body --full --allow-errors --max-time $timeout --insecure=$insecure --raw=$raw $req_url } }
  }
  if ($method in ["head" "options"]) { return $resp }
  if $allow_errors { $resp } else if $resp.status >= 400 { error make --unspanned { msg: $"HTTP ($resp.status): ($resp.body)" } } else if $full { {status: $resp.status, headers: $resp.headers, body: $resp.body} } else if $resp.status == 204 { null } else { $resp.body }
}

def base-url-completer [] { ["https://osconfig.googleapis.com"] }
def auth-scheme-completer [] { ["bearer"] }

# Completers for enum parameters
def xgafv-completer [] { ["1" "2"] }
def alt-completer [] { ["json" "media" "proto"] }

# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "v1beta create-lookup-effective-guest-policy" } } | get name | first)
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
export def "v1beta create-lookup-effective-guest-policy" [
  instance: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
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
  --os-architecture: string # Architecture of OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --os-short-name: string # Short name of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that instance.
  --os-version: string # Version of the OS running on the instance. The OS Config agent only provides this field for targeting if OS Inventory is enabled for that VM instance.
]: any -> record<packageRepositories: table<packageRepository: record, source: string>, packages: table<package: record, source: string>, softwareRecipes: table<softwareRecipe: record, source: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({instance: (encode-path-segment $instance)} | format pattern "/v1beta/{instance}:lookupEffectiveGuestPolicy") $qp)
  let req_body = {"osArchitecture": $os_architecture, "osShortName": $os_short_name, "osVersion": $os_version} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Delete an OS Config patch deployment.
#
# DELETE /v1beta/{name}
# operationId: osconfig.projects.patchDeployments.delete
export def "v1beta delete" [
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
]: nothing -> record {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get the patch job. This can be used to track the progress of an ongoing patch job or review the details of completed jobs.
#
# GET /v1beta/{name}
# operationId: osconfig.projects.patchJobs.get
export def "v1beta get" [
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
]: nothing -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Update an OS Config patch deployment.
#
# PATCH /v1beta/{name}
# operationId: osconfig.projects.patchDeployments.patch
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
# --oneTimeSchedule shape: {executeTime?: string}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --recurringSchedule shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta update" [
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
  --update-mask: string # Optional. Field mask that controls which fields of the patch deployment should be updated.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --body-name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment.
  --one-time-schedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurring-schedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "updateMask" $update_mask "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}") $qp)
  let req_body = {"description": $description, "duration": $duration, "instanceFilter": $instance_filter, "name": $body_name, "oneTimeSchedule": $one_time_schedule, "patchConfig": $patch_config, "recurringSchedule": $recurring_schedule, "rollout": $rollout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Cancel a patch job. The patch job must be active. Canceled patch jobs cannot be restarted.
#
# POST /v1beta/{name}:cancel
# operationId: osconfig.projects.patchJobs.cancel
export def "v1beta cancel" [
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
  --body: record
]: any -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}:cancel") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Change state of patch deployment to "PAUSED". Patch deployment in paused state doesn't generate patch jobs.
#
# POST /v1beta/{name}:pause
# operationId: osconfig.projects.patchDeployments.pause
export def "v1beta pause" [
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
  --body: record
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}:pause") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Change state of patch deployment back to "ACTIVE". Patch deployment in active state continues to generate patch jobs.
#
# POST /v1beta/{name}:resume
# operationId: osconfig.projects.patchDeployments.resume
export def "v1beta create-resume" [
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
  --body: record
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({name: (encode-path-segment $name)} | format pattern "/v1beta/{name}:resume") $qp)
  let req_body = $body
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a page of OS Config guest policies.
#
# GET /v1beta/{parent}/guestPolicies
# operationId: osconfig.projects.guestPolicies.list
export def "v1beta-guest-policies list" [
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
  --page-size: int # The maximum number of guest policies to return.
  --page-token: string # A pagination token returned from a previous call to `ListGuestPolicies` that indicates where this listing should continue from.
]: nothing -> record<guestPolicies: table<assignment: record, createTime: string, description: string, etag: string, name: string, packageRepositories: list, packages: list, recipes: list, updateTime: string>, nextPageToken: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/guestPolicies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an OS Config guest policy.
#
# POST /v1beta/{parent}/guestPolicies
# operationId: osconfig.projects.guestPolicies.create
# --assignment shape: {groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, osTypes?: list, zones?: list<string>}
# --packageRepositories item shape: {apt?: record, goo?: record, yum?: record, zypper?: record}
# --packages item shape: {desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", manager?: "MANAGER_UNSPECIFIED"|"ANY"|"APT"|"YUM"|"ZYPPER"|"GOO", name?: string}
# --recipes item shape: {artifacts?: list, desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", installSteps?: list, name?: string, updateSteps?: list, version?: string}
export def "v1beta-guest-policies create" [
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
  --guest-policy-id: string # Required. The logical name of the guest policy in the project with the following restrictions: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --assignment: record # An assignment represents the group or groups of VM instances that the policy applies to. If an assignment is empty, it applies to all VM instances. Otherwise, the targeted VM instances must meet all the criteria specified. So if both labels and zones are specified, the policy applies to VM instances with those labels and in those zones. — shape: {groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, osTypes?: list, zones?: list<string>}
  --description: string # Description of the guest policy. Length of the description is limited to 1024 characters.
  --etag: string # The etag for this guest policy. If this is provided on update, it must match the server's etag.
  --name: string # Required. Unique name of the resource in this project using one of the following forms: `projects/{project_number}/guestPolicies/{guest_policy_id}`.
  --package-repositories: list # A list of package repositories to configure on the VM instance. This is done before any other configs are applied so they can use these repos. Package repositories are only configured if the corresponding package manager(s) are available. — item shape: {apt?: record, goo?: record, yum?: record, zypper?: record}
  --packages: list # The software packages to be managed by this policy. — item shape: {desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", manager?: "MANAGER_UNSPECIFIED"|"ANY"|"APT"|"YUM"|"ZYPPER"|"GOO", name?: string}
  --recipes: list # A list of Recipes to install on the VM instance. — item shape: {artifacts?: list, desiredState?: "DESIRED_STATE_UNSPECIFIED"|"INSTALLED"|"UPDATED"|"REMOVED", installSteps?: list, name?: string, updateSteps?: list, version?: string}
]: any -> record<assignment: record<groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, osTypes: list<record>, zones: list<string>>, createTime: string, description: string, etag: string, name: string, packageRepositories: table<apt: record, goo: record, yum: record, zypper: record>, packages: table<desiredState: string, manager: string, name: string>, recipes: table<artifacts: list, desiredState: string, installSteps: list, name: string, updateSteps: list, version: string>, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "guestPolicyId" $guest_policy_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/guestPolicies") $qp)
  let req_body = {"assignment": $assignment, "description": $description, "etag": $etag, "name": $name, "packageRepositories": $package_repositories, "packages": $packages, "recipes": $recipes} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a list of instance details for a given patch job.
#
# GET /v1beta/{parent}/instanceDetails
# operationId: osconfig.projects.patchJobs.instanceDetails.list
export def "v1beta-instance-details list" [
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
  --filter: string # A filter expression that filters results listed in the response. This field supports filtering results by instance zone, name, state, or `failure_reason`.
  --page-size: int # The maximum number of instance details records to return. Default is 100.
  --page-token: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchJobInstanceDetails: table<attemptCount: string, failureReason: string, instanceSystemId: string, name: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/instanceDetails") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Get a page of OS Config patch deployments.
#
# GET /v1beta/{parent}/patchDeployments
# operationId: osconfig.projects.patchDeployments.list
export def "v1beta-patch-deployments list" [
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
  --page-size: int # Optional. The maximum number of patch deployments to return. Default is 100.
  --page-token: string # Optional. A pagination token returned from a previous call to ListPatchDeployments that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchDeployments: table<createTime: string, description: string, duration: string, instanceFilter: record, lastExecuteTime: string, name: string, oneTimeSchedule: record, patchConfig: record, recurringSchedule: record, rollout: record, state: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/patchDeployments") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Create an OS Config patch deployment.
#
# POST /v1beta/{parent}/patchDeployments
# operationId: osconfig.projects.patchDeployments.create
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
# --oneTimeSchedule shape: {executeTime?: string}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --recurringSchedule shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta-patch-deployments create" [
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
  --patch-deployment-id: string # Required. A name for the patch deployment in the project. When creating a name the following rules apply: * Must contain only lowercase letters, numbers, and hyphens. * Must start with a letter. * Must be between 1-63 characters. * Must end with a number or a letter. * Must be unique within the project.
  --description: string # Optional. Description of the patch deployment. Length of the description is limited to 1024 characters.
  --duration: string # Optional. Duration of the patch. After the duration ends, the patch times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --name: string # Unique name for the patch deployment resource in a project. The patch deployment name is in the form: `projects/{project_id}/patchDeployments/{patch_deployment_id}`. This field is ignored when you create a new patch deployment.
  --one-time-schedule: record # Sets the time for a one time patch deployment. Timestamp is in [RFC3339](https://www.ietf.org/rfc/rfc3339.txt) text format. — shape: {executeTime?: string}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --recurring-schedule: record # Sets the time for recurring patch deployments. — shape: {endTime?: string, frequency?: "FREQUENCY_UNSPECIFIED"|"WEEKLY"|"MONTHLY"|"DAILY", monthly?: record, startTime?: string, timeOfDay?: record, timeZone?: record, weekly?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, duration: string, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, lastExecuteTime: string, name: string, oneTimeSchedule: record<executeTime: string>, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, recurringSchedule: record<endTime: string, frequency: string, lastExecuteTime: string, monthly: record<monthDay: int, weekDayOfMonth: record>, nextExecuteTime: string, startTime: string, timeOfDay: record<hours: int, minutes: int, nanos: int, seconds: int>, timeZone: record<id: string, version: string>, weekly: record<dayOfWeek: string>>, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "patchDeploymentId" $patch_deployment_id "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/patchDeployments") $qp)
  let req_body = {"description": $description, "duration": $duration, "instanceFilter": $instance_filter, "name": $name, "oneTimeSchedule": $one_time_schedule, "patchConfig": $patch_config, "recurringSchedule": $recurring_schedule, "rollout": $rollout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}

# Get a list of patch jobs.
#
# GET /v1beta/{parent}/patchJobs
# operationId: osconfig.projects.patchJobs.list
export def "v1beta-patch-jobs list" [
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
  --filter: string # If provided, this field specifies the criteria that must be met by patch jobs to be included in the response. Currently, filtering is only available on the patch_deployment field.
  --page-size: int # The maximum number of instance status to return.
  --page-token: string # A pagination token returned from a previous call that indicates where this listing should continue from.
]: nothing -> record<nextPageToken: string, patchJobs: table<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record, instanceFilter: record, name: string, patchConfig: record, patchDeployment: string, percentComplete: float, rollout: record, state: string, updateTime: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar") (serialize-qp "filter" $filter "scalar") (serialize-qp "pageSize" $page_size "scalar") (serialize-qp "pageToken" $page_token "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/patchJobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json"
}

# Patch VM instances by creating and running a patch job.
#
# POST /v1beta/{parent}/patchJobs:execute
# operationId: osconfig.projects.patchJobs.execute
# --instanceFilter shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
# --patchConfig shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
# --rollout shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
export def "v1beta-patch-jobs-execute create" [
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
  --description: string # Description of the patch job. Length of the description is limited to 1024 characters.
  --display-name: string # Display name for this patch job. This does not have to be unique.
  --body-dry-run: oneof<nothing, bool> # If this patch is a dry-run only, instances are contacted but will do nothing.
  --duration: string # Duration of the patch job. After the duration ends, the patch job times out. (format: google-duration)
  --instance-filter: record # A filter to target VM instances for patching. The targeted VMs must meet all criteria specified. So if both labels and zones are specified, the patch job targets only VMs with those labels and in those zones. — shape: {all?: bool, groupLabels?: list, instanceNamePrefixes?: list<string>, instances?: list<string>, zones?: list<string>}
  --patch-config: record # Patch configuration specifications. Contains details on how to apply the patch(es) to a VM instance. — shape: {apt?: record, goo?: record, migInstancesAllowed?: bool, postStep?: record, preStep?: record, rebootConfig?: "REBOOT_CONFIG_UNSPECIFIED"|"DEFAULT"|"ALWAYS"|"NEVER", windowsUpdate?: record, yum?: record, zypper?: record}
  --rollout: record # Patch rollout configuration specifications. Contains details on the concurrency control when applying patch(es) to all targeted VMs. — shape: {disruptionBudget?: record, mode?: "MODE_UNSPECIFIED"|"ZONE_BY_ZONE"|"CONCURRENT_ZONES"}
]: any -> record<createTime: string, description: string, displayName: string, dryRun: bool, duration: string, errorMessage: string, instanceDetailsSummary: record<ackedInstanceCount: string, applyingPatchesInstanceCount: string, downloadingPatchesInstanceCount: string, failedInstanceCount: string, inactiveInstanceCount: string, noAgentDetectedInstanceCount: string, notifiedInstanceCount: string, pendingInstanceCount: string, postPatchStepInstanceCount: string, prePatchStepInstanceCount: string, rebootingInstanceCount: string, startedInstanceCount: string, succeededInstanceCount: string, succeededRebootRequiredInstanceCount: string, timedOutInstanceCount: string>, instanceFilter: record<all: bool, groupLabels: list<record>, instanceNamePrefixes: list<string>, instances: list<string>, zones: list<string>>, name: string, patchConfig: record<apt: record<excludes: list, exclusivePackages: list, type: string>, goo: record, migInstancesAllowed: bool, postStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, preStep: record<linuxExecStepConfig: record, windowsExecStepConfig: record>, rebootConfig: string, windowsUpdate: record<classifications: list, excludes: list, exclusivePatches: list>, yum: record<excludes: list, exclusivePackages: list, minimal: bool, security: bool>, zypper: record<categories: list, excludes: list, exclusivePatches: list, severities: list, withOptional: bool, withUpdate: bool>>, patchDeployment: string, percentComplete: float, rollout: record<disruptionBudget: record<fixed: int, percent: int>, mode: string>, state: string, updateTime: string> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  let qp = [(serialize-qp "$.xgafv" $xgafv "scalar") (serialize-qp "access_token" $access_token "scalar") (serialize-qp "alt" $alt "scalar") (serialize-qp "callback" $callback "scalar") (serialize-qp "fields" $fields "scalar") (serialize-qp "key" $key "scalar") (serialize-qp "oauth_token" $oauth_token "scalar") (serialize-qp "prettyPrint" $pretty_print "scalar") (serialize-qp "quotaUser" $quota_user "scalar") (serialize-qp "upload_protocol" $upload_protocol "scalar") (serialize-qp "uploadType" $upload_type "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({parent: (encode-path-segment $parent)} | format pattern "/v1beta/{parent}/patchJobs:execute") $qp)
  let req_body = {"description": $description, "displayName": $display_name, "dryRun": $body_dry_run, "duration": $duration, "instanceFilter": $instance_filter, "patchConfig": $patch_config, "rollout": $rollout} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body
}
