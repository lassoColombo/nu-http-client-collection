# Auto-generated client for SiteRecoveryManagementClient v2018-07-10
# Source: https://api.apis.guru/v2/specs/azure.com/recoveryservicessiterecovery-service/2018-07-10/swagger.json
# Auth: --token flag or $env.SITERECOVERYMANAGEMENTCLIENT_TOKEN

const BASE_URL = "https://management.azure.com"

# Build auth: returns {scheme: string, headers: record, query: string, location: string}.
# `location` is "header" | "query" | "cookie" | "none" and tells dry-run callers
# where the token went without inspecting headers/query themselves.
def build-auth [token?: string, auth_scheme?: string]: nothing -> record {
  let token_val = if ($token != null) and ($token | is-not-empty) { $token } else { $env | get -o SITERECOVERYMANAGEMENTCLIENT_TOKEN | default "" }
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

def base-url-completer [] { ["https://management.azure.com"] }
def auth-scheme-completer [] { ["bearer"] }


# List all available API commands with their parameters
export def commands []: nothing -> table {
  let builtin_flags = ["base-url" "token" "auth-scheme" "insecure" "max-time" "raw" "allow-errors" "full" "dry-run" "accept" "help"]
  let mod_name = (scope modules | where { $in.commands | any { $in.name == "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results list" } } | get name | first)
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

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults
# operationId: ReplicationEligibilityResults_List
export def "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results list" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Compute/virtualMachines/{virtual_machine_name}/providers/Microsoft.RecoveryServices/replicationEligibilityResults") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the validation errors in case the VM is unsuitable for protection.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.Compute/virtualMachines/{virtualMachineName}/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default
# operationId: ReplicationEligibilityResults_Get
export def "subscriptions-resource-groups-providers-microsoft-compute-virtual-machines-providers-microsoft-recovery-services-replication-eligibility-results-default get" [
  subscription_id: string
  resource_group_name: string
  virtual_machine_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<id: string, name: string, properties: record<clientRequestId: string, errors: list<record>>, type: string> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($virtual_machine_name | is-empty) { error make --unspanned { msg: "path parameter 'virtualMachineName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), virtual_machine_name: (encode-path-segment $virtual_machine_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.Compute/virtualMachines/{virtual_machine_name}/providers/Microsoft.RecoveryServices/replicationEligibilityResults/default") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Returns the list of available operations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/operations
# operationId: Operations_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-operations list" [
  subscription_id: string
  resource_group_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<display: record, name: string, origin: string, properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/operations") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of configured email notification(alert) configurations.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings
# operationId: ReplicationAlertSettings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationAlertSettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets an email notification(alert) configuration.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# operationId: ReplicationAlertSettings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  alert_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($alert_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'alertSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), alert_setting_name: (encode-path-segment $alert_setting_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationAlertSettings/{alert_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Configures email notifications for this vault.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationAlertSettings/{alertSettingName}
# operationId: ReplicationAlertSettings_Create
# --properties shape: {customEmailAddresses?: list<string>, locale?: string, sendToOwners?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-alert-settings create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  alert_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Properties of a configure alert request. — shape: {customEmailAddresses?: list<string>, locale?: string, sendToOwners?: string}
]: any -> record<properties: record<customEmailAddresses: list<string>, locale: string, sendToOwners: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($alert_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'alertSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), alert_setting_name: (encode-path-segment $alert_setting_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationAlertSettings/{alert_setting_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of Azure Site Recovery events.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents
# operationId: ReplicationEvents_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-events list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationEvents") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$filter": $filter} | compact), body: null}
}

# Get the details of an Azure Site recovery event.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationEvents/{eventName}
# operationId: ReplicationEvents_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-events get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  event_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<affectedObjectFriendlyName: string, description: string, eventCode: string, eventSpecificDetails: record<instanceType: string>, eventType: string, fabricId: string, healthErrors: list<record>, providerSpecificDetails: record<instanceType: string>, severity: string, timeOfOccurrence: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($event_name | is-empty) { error make --unspanned { msg: "path parameter 'eventName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), event_name: (encode-path-segment $event_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationEvents/{event_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of ASR fabrics
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics
# operationId: ReplicationFabrics_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Purges the site.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics delete-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of an ASR fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Creates an Azure Site Recovery fabric.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}
# operationId: ReplicationFabrics_Create
# --properties shape: {customDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Properties of site details provided during the time of site creation — shape: {customDetails?: record}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Checks the consistency of the ASR fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/checkConsistency
# operationId: ReplicationFabrics_CheckConsistency
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-check-consistency check" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/checkConsistency") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Migrates the site to AAD.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/migratetoaad
# operationId: ReplicationFabrics_MigrateToAad
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-migratetoaad create-migrate-to-aad" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/migratetoaad") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Perform failover of the process server.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/reassociateGateway
# operationId: ReplicationFabrics_ReassociateGateway
# --properties shape: {containerName?: string, sourceProcessServerId?: string, targetProcessServerId?: string, updateType?: string, vmsToMigrate?: list<string>}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-reassociate-gateway create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of the Failover Process Server request. — shape: {containerName?: string, sourceProcessServerId?: string, targetProcessServerId?: string, updateType?: string, vmsToMigrate?: list<string>}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/reassociateGateway") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Deletes the site.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/remove
# operationId: ReplicationFabrics_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-remove delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/remove") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Renews certificate for the fabric.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/renewCertificate
# operationId: ReplicationFabrics_RenewCertificate
# --properties shape: {renewCertificateType?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-renew-certificate create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Renew Certificate input properties. — shape: {renewCertificateType?: string}
]: any -> record<properties: record<bcdrState: string, customDetails: record<instanceType: string>, encryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>, friendlyName: string, health: string, healthErrorDetails: list<record>, internalIdentifier: string, rolloverEncryptionDetails: record<kekCertExpiryDate: string, kekCertThumbprint: string, kekState: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/renewCertificate") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of logical networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks
# operationId: ReplicationLogicalNetworks_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-logical-networks list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationLogicalNetworks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a logical network with specified server id and logical network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationLogicalNetworks/{logicalNetworkName}
# operationId: ReplicationLogicalNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-logical-networks get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  logical_network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string, logicalNetworkDefinitionsStatus: string, logicalNetworkUsage: string, networkVirtualizationStatus: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($logical_network_name | is-empty) { error make --unspanned { msg: "path parameter 'logicalNetworkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), logical_network_name: (encode-path-segment $logical_network_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationLogicalNetworks/{logical_network_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of networks under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks
# operationId: ReplicationNetworks_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a network with specified server id and network name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}
# operationId: ReplicationNetworks_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricType: string, friendlyName: string, networkType: string, subnets: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets all the network mappings under a network.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings
# operationId: ReplicationNetworkMappings_ListByReplicationNetworks
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}/replicationNetworkMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Delete network mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  if ($network_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'networkMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name), network_mapping_name: (encode-path-segment $network_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}/replicationNetworkMappings/{network_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets network mapping by name.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  if ($network_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'networkMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name), network_mapping_name: (encode-path-segment $network_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}/replicationNetworkMappings/{network_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates network mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Update
# --properties shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  if ($network_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'networkMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name), network_mapping_name: (encode-path-segment $network_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}/replicationNetworkMappings/{network_mapping_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates network mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationNetworks/{networkName}/replicationNetworkMappings/{networkMappingName}
# operationId: ReplicationNetworkMappings_Create
# --properties shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-networks-replication-network-mappings create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  network_name: string
  network_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Common input details for network mapping operation. — shape: {fabricSpecificDetails?: record, recoveryFabricName?: string, recoveryNetworkId?: string}
]: any -> record<properties: record<fabricSpecificSettings: record<instanceType: string>, primaryFabricFriendlyName: string, primaryNetworkFriendlyName: string, primaryNetworkId: string, recoveryFabricArmId: string, recoveryFabricFriendlyName: string, recoveryNetworkFriendlyName: string, recoveryNetworkId: string, state: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($network_name | is-empty) { error make --unspanned { msg: "path parameter 'networkName' must be non-empty" } }
  if ($network_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'networkMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), network_name: (encode-path-segment $network_name), network_mapping_name: (encode-path-segment $network_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationNetworks/{network_name}/replicationNetworkMappings/{network_mapping_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of protection container for a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers
# operationId: ReplicationProtectionContainers_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the protection container details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# operationId: ReplicationProtectionContainers_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create a protection container.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}
# operationId: ReplicationProtectionContainers_Create
# --properties shape: {providerSpecificInput?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Create protection container input properties. — shape: {providerSpecificInput?: list}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Adds a protectable item to the replication protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/discoverProtectableItem
# operationId: ReplicationProtectionContainers_DiscoverProtectableItem
# --properties shape: {friendlyName?: string, ipAddress?: string, osType?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-discover-protectable-item create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Discover protectable item properties. — shape: {friendlyName?: string, ipAddress?: string, osType?: string}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/discoverProtectableItem") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Removes a protection container.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/remove
# operationId: ReplicationProtectionContainers_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-remove delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/remove") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of migration items in the protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems
# operationId: ReplicationMigrationItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Delete the migration item.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --delete-option: string # The delete option.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "deleteOption" $delete_option "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "deleteOption": $delete_option} | compact), body: null}
}

# Gets the details of a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates migration item.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Update
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Update migration item input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Enables migration.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}
# operationId: ReplicationMigrationItems_Create
# --properties shape: {policyId: string, providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Enable migration input properties. — shape: {policyId: string, providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrate
# operationId: ReplicationMigrationItems_Migrate
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migrate create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}/migrate") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the recovery points for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints
# operationId: MigrationRecoveryPoints_ListByReplicationMigrationItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migration-recovery-points list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}/migrationRecoveryPoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a recovery point for a migration item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/migrationRecoveryPoints/{migrationRecoveryPointName}
# operationId: MigrationRecoveryPoints_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-migration-recovery-points get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  migration_recovery_point_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<recoveryPointTime: string, recoveryPointType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  if ($migration_recovery_point_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationRecoveryPointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name), migration_recovery_point_name: (encode-path-segment $migration_recovery_point_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}/migrationRecoveryPoints/{migration_recovery_point_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Test migrate item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrate
# operationId: ReplicationMigrationItems_TestMigrate
# --properties shape: {providerSpecificDetails: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-test-migrate test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Test migrate input properties. — shape: {providerSpecificDetails: record}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}/testMigrate") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Test migrate cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationMigrationItems/{migrationItemName}/testMigrateCleanup
# operationId: ReplicationMigrationItems_TestMigrateCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-migration-items-test-migrate-cleanup test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  migration_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Test migrate cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentJob: record<jobId: string, jobName: string, startTime: string>, health: string, healthErrors: list<record>, machineName: string, migrationState: string, migrationStateDescription: string, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, recoveryServicesProviderId: string, testMigrateState: string, testMigrateStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($migration_item_name | is-empty) { error make --unspanned { msg: "path parameter 'migrationItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), migration_item_name: (encode-path-segment $migration_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationMigrationItems/{migration_item_name}/testMigrateCleanup") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of protectable items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems
# operationId: ReplicationProtectableItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protectable-items list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectableItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$filter": $filter} | compact), body: null}
}

# Gets the details of a protectable item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectableItems/{protectableItemName}
# operationId: ReplicationProtectableItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protectable-items get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  protectable_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<customDetails: record<instanceType: string>, friendlyName: string, protectionReadinessErrors: list<string>, protectionStatus: string, recoveryServicesProviderId: string, replicationProtectedItemId: string, supportedReplicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($protectable_item_name | is-empty) { error make --unspanned { msg: "path parameter 'protectableItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), protectable_item_name: (encode-path-segment $protectable_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectableItems/{protectable_item_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of Replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems
# operationId: ReplicationProtectedItems_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Purges protection.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items delete-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a Replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates protection.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Update
# --properties shape: {enableRdpOnTargetOption?: string, licenseType?: "NotSpecified"|"NoLicenseType"|"WindowsServer", providerSpecificDetails?: record, recoveryAvailabilitySetId?: string, recoveryAzureVMName?: string, recoveryAzureVMSize?: string, selectedRecoveryAzureNetworkId?: string, selectedSourceNicId?: string, selectedTfoAzureNetworkId?: string, vmNics?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Update protected item input properties. — shape: {enableRdpOnTargetOption?: string, licenseType?: "NotSpecified"|"NoLicenseType"|"WindowsServer", providerSpecificDetails?: record, recoveryAvailabilitySetId?: string, recoveryAzureVMName?: string, recoveryAzureVMSize?: string, selectedRecoveryAzureNetworkId?: string, selectedSourceNicId?: string, selectedTfoAzureNetworkId?: string, vmNics?: list}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Enables protection.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}
# operationId: ReplicationProtectedItems_Create
# --properties shape: {policyId?: string, protectableItemId?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Enable protection input properties. — shape: {policyId?: string, protectableItemId?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Resolve health errors.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/ResolveHealthErrors
# operationId: ReplicationProtectedItems_ResolveHealthErrors
# --properties shape: {healthErrors?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-resolve-health-errors create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Resolve health input properties. — shape: {healthErrors?: list}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/ResolveHealthErrors") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Add disk(s) for protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/addDisks
# operationId: ReplicationProtectedItems_AddDisks
# --properties shape: {providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-add-disks create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Add Disks input properties. — shape: {providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/addDisks") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Change or apply recovery point.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/applyRecoveryPoint
# operationId: ReplicationProtectedItems_ApplyRecoveryPoint
# --properties shape: {providerSpecificDetails?: record, recoveryPointId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-apply-recovery-point create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input properties to apply recovery point. — shape: {providerSpecificDetails?: record, recoveryPointId?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/applyRecoveryPoint") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute commit failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/failoverCommit
# operationId: ReplicationProtectedItems_FailoverCommit
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-failover-commit commit" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/failoverCommit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Execute planned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/plannedFailover
# operationId: ReplicationProtectedItems_PlannedFailover
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-planned-failover create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/plannedFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute Reverse Replication\Reprotect
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/reProtect
# operationId: ReplicationProtectedItems_Reprotect
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-re-protect create-reprotect" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Reverse replication input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/reProtect") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Get recovery points for a replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints
# operationId: RecoveryPoints_ListByReplicationProtectedItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-recovery-points list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/recoveryPoints") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Get a recovery point.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/recoveryPoints/{recoveryPointName}
# operationId: RecoveryPoints_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-recovery-points get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  recovery_point_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<providerSpecificDetails: record<instanceType: string>, recoveryPointTime: string, recoveryPointType: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  if ($recovery_point_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPointName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name), recovery_point_name: (encode-path-segment $recovery_point_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/recoveryPoints/{recovery_point_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Disables protection.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/remove
# operationId: ReplicationProtectedItems_Delete
# --properties shape: {disableProtectionReason?: "NotSpecified"|"MigrationComplete", replicationProviderInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-remove delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Disable protection input properties. — shape: {disableProtectionReason?: "NotSpecified"|"MigrationComplete", replicationProviderInput?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/remove") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Removes disk(s).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/removeDisks
# operationId: ReplicationProtectedItems_RemoveDisks
# --properties shape: {providerSpecificDetails?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-remove-disks delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Remove Disk input properties. — shape: {providerSpecificDetails?: record}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/removeDisks") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Resynchronize or repair replication.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/repairReplication
# operationId: ReplicationProtectedItems_RepairReplication
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-repair-replication create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/repairReplication") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of target compute sizes for the replication protected item.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/targetComputeSizes
# operationId: TargetComputeSizes_ListByReplicationProtectedItems
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-target-compute-sizes list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<id: string, name: string, properties: record, type: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/targetComputeSizes") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Execute test failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailover
# operationId: ReplicationProtectedItems_TestFailover
# --properties shape: {failoverDirection?: string, networkId?: string, networkType?: string, providerSpecificDetails?: record, skipTestFailoverCleanup?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-test-failover test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, networkId?: string, networkType?: string, providerSpecificDetails?: record, skipTestFailoverCleanup?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/testFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute test failover cleanup.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/testFailoverCleanup
# operationId: ReplicationProtectedItems_TestFailoverCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-test-failover-cleanup test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Input definition for test failover cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/testFailoverCleanup") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute unplanned failover
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicatedProtectedItemName}/unplannedFailover
# operationId: ReplicationProtectedItems_UnplannedFailover
# --properties shape: {failoverDirection?: string, providerSpecificDetails?: record, sourceSiteOperations?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-unplanned-failover create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replicated_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Input definition for planned failover input properties. — shape: {failoverDirection?: string, providerSpecificDetails?: record, sourceSiteOperations?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replicated_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicatedProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replicated_protected_item_name: (encode-path-segment $replicated_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replicated_protected_item_name}/unplannedFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Update the mobility service on a protected item.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectedItems/{replicationProtectedItemName}/updateMobilityService
# operationId: ReplicationProtectedItems_UpdateMobilityService
# --properties shape: {runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protected-items-update-mobility-service update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  replication_protected_item_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an update mobility service request. — shape: {runAsAccountId?: string}
]: any -> record<properties: record<activeLocation: string, allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, failoverHealth: string, failoverRecoveryPointId: string, friendlyName: string, healthErrors: list<record>, lastSuccessfulFailoverTime: string, lastSuccessfulTestFailoverTime: string, policyFriendlyName: string, policyId: string, primaryFabricFriendlyName: string, primaryFabricProvider: string, primaryProtectionContainerFriendlyName: string, protectableItemId: string, protectedItemType: string, protectionState: string, protectionStateDescription: string, providerSpecificDetails: record<instanceType: string>, recoveryContainerId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, recoveryProtectionContainerFriendlyName: string, recoveryServicesProviderId: string, replicationHealth: string, testFailoverState: string, testFailoverStateDescription: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($replication_protected_item_name | is-empty) { error make --unspanned { msg: "path parameter 'replicationProtectedItemName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), replication_protected_item_name: (encode-path-segment $replication_protected_item_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectedItems/{replication_protected_item_name}/updateMobilityService") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of protection container mappings for a protection container.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings
# operationId: ReplicationProtectionContainerMappings_ListByReplicationProtectionContainers
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Purge protection container mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings delete-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings/{mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets a protection container mapping/
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings/{mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update protection container mapping.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Update
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Container pairing update input. — shape: {providerSpecificInput?: record}
]: any -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings/{mapping_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Create protection container mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}
# operationId: ReplicationProtectionContainerMappings_Create
# --properties shape: {policyId?: string, providerSpecificInput?: record, targetProtectionContainerId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Configure pairing input properties. — shape: {policyId?: string, providerSpecificInput?: record, targetProtectionContainerId?: string}
]: any -> record<properties: record<health: string, healthErrorDetails: list<record>, policyFriendlyName: string, policyId: string, providerSpecificDetails: record<instanceType: string>, sourceFabricFriendlyName: string, sourceProtectionContainerFriendlyName: string, state: string, targetFabricFriendlyName: string, targetProtectionContainerFriendlyName: string, targetProtectionContainerId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings/{mapping_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Remove protection container mapping.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/replicationProtectionContainerMappings/{mappingName}/remove
# operationId: ReplicationProtectionContainerMappings_Delete
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-replication-protection-container-mappings-remove delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Unpairing input properties. — shape: {providerSpecificInput?: record}
]: any -> any {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  if ($mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'mappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name), mapping_name: (encode-path-segment $mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/replicationProtectionContainerMappings/{mapping_name}/remove") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Switches protection from one container to another or one replication provider to another.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationProtectionContainers/{protectionContainerName}/switchprotection
# operationId: ReplicationProtectionContainers_SwitchProtection
# --properties shape: {providerSpecificDetails?: record, replicationProtectedItemName?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-protection-containers-switchprotection create-switch" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  protection_container_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Switch protection input properties. — shape: {providerSpecificDetails?: record, replicationProtectedItemName?: string}
]: any -> record<properties: record<fabricFriendlyName: string, fabricSpecificDetails: record<instanceType: string>, fabricType: string, friendlyName: string, pairingStatus: string, protectedItemCount: int, role: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($protection_container_name | is-empty) { error make --unspanned { msg: "path parameter 'protectionContainerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), protection_container_name: (encode-path-segment $protection_container_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationProtectionContainers/{protection_container_name}/switchprotection") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of registered recovery services providers for the fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders
# operationId: ReplicationRecoveryServicesProviders_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Purges recovery service provider from fabric
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Purge
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers delete-purge" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($provider_name | is-empty) { error make --unspanned { msg: "path parameter 'providerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), provider_name: (encode-path-segment $provider_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders/{provider_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a recovery services provider.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($provider_name | is-empty) { error make --unspanned { msg: "path parameter 'providerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), provider_name: (encode-path-segment $provider_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders/{provider_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Adds a recovery services provider.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}
# operationId: ReplicationRecoveryServicesProviders_Create
# --properties shape: {authenticationIdentityInput: record, machineName: string, resourceAccessIdentityInput: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # The properties of an add provider request. — shape: {authenticationIdentityInput: record, machineName: string, resourceAccessIdentityInput: record}
]: any -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($provider_name | is-empty) { error make --unspanned { msg: "path parameter 'providerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), provider_name: (encode-path-segment $provider_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders/{provider_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Refresh details from the recovery services provider.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/refreshProvider
# operationId: ReplicationRecoveryServicesProviders_RefreshProvider
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers-refresh-provider refresh" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedScenarios: list<string>, authenticationIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, connectionStatus: string, draIdentifier: string, fabricFriendlyName: string, fabricType: string, friendlyName: string, healthErrorDetails: list<record>, lastHeartBeat: string, protectedItemCount: int, providerVersion: string, providerVersionDetails: record<expiryDate: string, status: string, version: string>, providerVersionExpiryDate: string, providerVersionState: string, resourceAccessIdentityDetails: record<aadAuthority: string, applicationId: string, audience: string, objectId: string, tenantId: string>, serverVersion: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($provider_name | is-empty) { error make --unspanned { msg: "path parameter 'providerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), provider_name: (encode-path-segment $provider_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders/{provider_name}/refreshProvider") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes provider from fabric. Note: Deleting provider for any fabric other than SingleHost is unsupported. To maintain backward compatibility for released clients the object "deleteRspInput" is used (if the object is empty we assume that it is old client and continue the old behavior).
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationRecoveryServicesProviders/{providerName}/remove
# operationId: ReplicationRecoveryServicesProviders_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-recovery-services-providers-remove delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  provider_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($provider_name | is-empty) { error make --unspanned { msg: "path parameter 'providerName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), provider_name: (encode-path-segment $provider_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationRecoveryServicesProviders/{provider_name}/remove") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of storage classification objects under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications
# operationId: ReplicationStorageClassifications_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a storage classification.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}
# operationId: ReplicationStorageClassifications_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($storage_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), storage_classification_name: (encode-path-segment $storage_classification_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications/{storage_classification_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of storage classification mappings objects under a storage.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings
# operationId: ReplicationStorageClassificationMappings_ListByReplicationStorageClassifications
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($storage_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), storage_classification_name: (encode-path-segment $storage_classification_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications/{storage_classification_name}/replicationStorageClassificationMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Delete a storage classification mapping.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($storage_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationName' must be non-empty" } }
  if ($storage_classification_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), storage_classification_name: (encode-path-segment $storage_classification_name), storage_classification_mapping_name: (encode-path-segment $storage_classification_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications/{storage_classification_name}/replicationStorageClassificationMappings/{storage_classification_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a storage classification mapping.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<targetStorageClassificationId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($storage_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationName' must be non-empty" } }
  if ($storage_classification_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), storage_classification_name: (encode-path-segment $storage_classification_name), storage_classification_mapping_name: (encode-path-segment $storage_classification_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications/{storage_classification_name}/replicationStorageClassificationMappings/{storage_classification_mapping_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Create storage classification mapping.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationStorageClassifications/{storageClassificationName}/replicationStorageClassificationMappings/{storageClassificationMappingName}
# operationId: ReplicationStorageClassificationMappings_Create
# --properties shape: {targetStorageClassificationId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replication-storage-classifications-replication-storage-classification-mappings create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  storage_classification_name: string
  storage_classification_mapping_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Storage mapping input properties. — shape: {targetStorageClassificationId?: string}
]: any -> record<properties: record<targetStorageClassificationId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($storage_classification_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationName' must be non-empty" } }
  if ($storage_classification_mapping_name | is-empty) { error make --unspanned { msg: "path parameter 'storageClassificationMappingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), storage_classification_name: (encode-path-segment $storage_classification_name), storage_classification_mapping_name: (encode-path-segment $storage_classification_mapping_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationStorageClassifications/{storage_classification_name}/replicationStorageClassificationMappings/{storage_classification_mapping_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of vCenter registered under a fabric.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters
# operationId: ReplicationvCenters_ListByReplicationFabrics
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationvCenters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Remove vCenter operation.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($v_center_name | is-empty) { error make --unspanned { msg: "path parameter 'vCenterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), v_center_name: (encode-path-segment $v_center_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationvCenters/{v_center_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the details of a vCenter.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($v_center_name | is-empty) { error make --unspanned { msg: "path parameter 'vCenterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), v_center_name: (encode-path-segment $v_center_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationvCenters/{v_center_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Update vCenter operation.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Update
# --properties shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an update vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($v_center_name | is-empty) { error make --unspanned { msg: "path parameter 'vCenterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), v_center_name: (encode-path-segment $v_center_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationvCenters/{v_center_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Add vCenter.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationFabrics/{fabricName}/replicationvCenters/{vCenterName}
# operationId: ReplicationvCenters_Create
# --properties shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-fabrics-replicationv-centers create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  fabric_name: string
  v_center_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # The properties of an add vCenter request. — shape: {friendlyName?: string, ipAddress?: string, port?: string, processServerId?: string, runAsAccountId?: string}
]: any -> record<properties: record<discoveryStatus: string, fabricArmResourceName: string, friendlyName: string, healthErrors: list<record>, infrastructureId: string, internalId: string, ipAddress: string, lastHeartbeat: string, port: string, processServerId: string, runAsAccountId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($fabric_name | is-empty) { error make --unspanned { msg: "path parameter 'fabricName' must be non-empty" } }
  if ($v_center_name | is-empty) { error make --unspanned { msg: "path parameter 'vCenterName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), fabric_name: (encode-path-segment $fabric_name), v_center_name: (encode-path-segment $v_center_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationFabrics/{fabric_name}/replicationvCenters/{v_center_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of jobs.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs
# operationId: ReplicationJobs_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "$filter": $filter} | compact), body: null}
}

# Exports the details of the Azure Site Recovery jobs of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/export
# operationId: ReplicationJobs_Export
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-export export" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --affected-object-types: string # The type of objects.
  --end-time: string # Date time to get jobs up to.
  --fabric-id: string # The Id of the fabric to search jobs under.
  --job-status: string # The states of the job to be filtered can be in.
  --start-time: string # Date time to get jobs from.
]: any -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs/export") $qp)
  let req_body = {"affectedObjectTypes": $affected_object_types, "endTime": $end_time, "fabricId": $fabric_id, "jobStatus": $job_status, "startTime": $start_time} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the job details.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}
# operationId: ReplicationJobs_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs/{job_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Cancels the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/cancel
# operationId: ReplicationJobs_Cancel
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-cancel cancel" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs/{job_name}/cancel") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Restarts the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/restart
# operationId: ReplicationJobs_Restart
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-restart restart" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs/{job_name}/restart") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Resumes the specified job.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationJobs/{jobName}/resume
# operationId: ReplicationJobs_Resume
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-jobs-resume create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  job_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Resume job properties. — shape: {comments?: string}
]: any -> record<properties: record<activityId: string, allowedActions: list<string>, customDetails: record<affectedObjectDetails: record, instanceType: string>, endTime: string, errors: list<record>, friendlyName: string, scenarioName: string, startTime: string, state: string, stateDescription: string, targetInstanceType: string, targetObjectId: string, targetObjectName: string, tasks: list<record>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($job_name | is-empty) { error make --unspanned { msg: "path parameter 'jobName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), job_name: (encode-path-segment $job_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationJobs/{job_name}/resume") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of migration items in the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationMigrationItems
# operationId: ReplicationMigrationItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-migration-items list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --skip-token: string # The pagination token.
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "skipToken" $skip_token "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationMigrationItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "skipToken": $skip_token, "$filter": $filter} | compact), body: null}
}

# Gets all the network mappings under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworkMappings
# operationId: ReplicationNetworkMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-network-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationNetworkMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of networks. View-only API.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationNetworks
# operationId: ReplicationNetworks_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-networks list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationNetworks") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of replication policies
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies
# operationId: ReplicationPolicies_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationPolicies") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Delete the policy.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationPolicies/{policy_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the requested policy.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationPolicies/{policy_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the policy.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Update
# --properties shape: {replicationProviderSettings?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Policy update properties. — shape: {replicationProviderSettings?: record}
]: any -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationPolicies/{policy_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates the policy.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationPolicies/{policyName}
# operationId: ReplicationPolicies_Create
# --properties shape: {providerSpecificInput?: record}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-policies create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  policy_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Policy creation properties. — shape: {providerSpecificInput?: record}
]: any -> record<properties: record<friendlyName: string, providerSpecificDetails: record<instanceType: string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($policy_name | is-empty) { error make --unspanned { msg: "path parameter 'policyName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), policy_name: (encode-path-segment $policy_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationPolicies/{policy_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of replication protected items.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectedItems
# operationId: ReplicationProtectedItems_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protected-items list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --skip-token: string # The pagination token. Possible values: "FabricId" or "FabricId_CloudId" or null
  --filter: string # OData filter options.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar") (serialize-qp "skipToken" $skip_token "scalar") (serialize-qp "$filter" $filter "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationProtectedItems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version, "skipToken": $skip_token, "$filter": $filter} | compact), body: null}
}

# Gets the list of all protection container mappings in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainerMappings
# operationId: ReplicationProtectionContainerMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protection-container-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationProtectionContainerMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of all protection containers in a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationProtectionContainers
# operationId: ReplicationProtectionContainers_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-protection-containers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationProtectionContainers") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of recovery plans.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans
# operationId: ReplicationRecoveryPlans_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Deletes the specified recovery plan.
#
# DELETE /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Delete
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans delete" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> any {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "delete" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the requested recovery plan.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates the given recovery plan.
#
# PATCH /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Update
# --properties shape: {groups?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans update" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  --properties: record # Recovery plan update properties. — shape: {groups?: list}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "patch" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Creates a recovery plan with the given details.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}
# operationId: ReplicationRecoveryPlans_Create
# --properties shape: {failoverDeploymentModel?: "NotApplicable"|"Classic"|"ResourceManager", groups: list, primaryFabricId: string, recoveryFabricId: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan creation properties. — shape: {failoverDeploymentModel?: "NotApplicable"|"Classic"|"ResourceManager", groups: list, primaryFabricId: string, recoveryFabricId: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute commit failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/failoverCommit
# operationId: ReplicationRecoveryPlans_FailoverCommit
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-failover-commit commit" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/failoverCommit") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Execute planned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/plannedFailover
# operationId: ReplicationRecoveryPlans_PlannedFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-planned-failover create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan planned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/plannedFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute reprotect of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/reProtect
# operationId: ReplicationRecoveryPlans_Reprotect
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-re-protect create-reprotect" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/reProtect") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Execute test failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailover
# operationId: ReplicationRecoveryPlans_TestFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", networkId?: string, networkType: string, providerSpecificDetails?: list, skipTestFailoverCleanup?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-test-failover test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan test failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", networkId?: string, networkType: string, providerSpecificDetails?: list, skipTestFailoverCleanup?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/testFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute test failover cleanup of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/testFailoverCleanup
# operationId: ReplicationRecoveryPlans_TestFailoverCleanup
# --properties shape: {comments?: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-test-failover-cleanup test" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan test failover cleanup input properties. — shape: {comments?: string}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/testFailoverCleanup") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Execute unplanned failover of the recovery plan.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryPlans/{recoveryPlanName}/unplannedFailover
# operationId: ReplicationRecoveryPlans_UnplannedFailover
# --properties shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list, sourceSiteOperations: "Required"|"NotRequired"}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-plans-unplanned-failover create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  recovery_plan_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Recovery plan unplanned failover input properties. — shape: {failoverDirection: "PrimaryToRecovery"|"RecoveryToPrimary", providerSpecificDetails?: list, sourceSiteOperations: "Required"|"NotRequired"}
]: any -> record<properties: record<allowedOperations: list<string>, currentScenario: record<jobId: string, scenarioName: string, startTime: string>, currentScenarioStatus: string, currentScenarioStatusDescription: string, failoverDeploymentModel: string, friendlyName: string, groups: list<record>, lastPlannedFailoverTime: string, lastTestFailoverTime: string, lastUnplannedFailoverTime: string, primaryFabricFriendlyName: string, primaryFabricId: string, recoveryFabricFriendlyName: string, recoveryFabricId: string, replicationProviders: list<string>>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($recovery_plan_name | is-empty) { error make --unspanned { msg: "path parameter 'recoveryPlanName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), recovery_plan_name: (encode-path-segment $recovery_plan_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryPlans/{recovery_plan_name}/unplannedFailover") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of registered recovery services providers in the vault. This is a view only api.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationRecoveryServicesProviders
# operationId: ReplicationRecoveryServicesProviders_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-recovery-services-providers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationRecoveryServicesProviders") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of storage classification mappings objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassificationMappings
# operationId: ReplicationStorageClassificationMappings_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-storage-classification-mappings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationStorageClassificationMappings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of storage classification objects under a vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationStorageClassifications
# operationId: ReplicationStorageClassifications_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-storage-classifications list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationStorageClassifications") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the data of supported OSes by SRS.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationSupportedOperatingSystems
# operationId: SupportedOperatingSystems_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-supported-operating-systems get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<supportedOsList: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationSupportedOperatingSystems") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the health summary for the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth
# operationId: ReplicationVaultHealth_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-health get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationVaultHealth") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Refreshes health summary of the vault.
#
# POST /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultHealth/default/refresh
# operationId: ReplicationVaultHealth_Refresh
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-health-default-refresh refresh" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<containersHealth: record<issues: list, resourceCount: int>, fabricsHealth: record<issues: list, resourceCount: int>, protectedItemsHealth: record<issues: list, resourceCount: int>, vaultErrors: list<record>>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationVaultHealth/default/refresh") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "post" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the list of vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings
# operationId: ReplicationVaultSetting_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationVaultSettings") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Gets the vault setting.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# operationId: ReplicationVaultSetting_Get
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings get" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  vault_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<properties: record<migrationSolutionId: string>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($vault_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), vault_setting_name: (encode-path-segment $vault_setting_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationVaultSettings/{vault_setting_name}") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}

# Updates vault setting. A vault setting object is a singleton per vault and it is always present by default.
#
# PUT /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationVaultSettings/{vaultSettingName}
# operationId: ReplicationVaultSetting_Create
# --properties shape: {migrationSolutionId: string}
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replication-vault-settings create" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  vault_setting_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
  properties: record # Input to create vault setting. — shape: {migrationSolutionId: string}
]: any -> record<properties: record<migrationSolutionId: string>> {
  let input = $in
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  if ($vault_setting_name | is-empty) { error make --unspanned { msg: "path parameter 'vaultSettingName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name), vault_setting_name: (encode-path-segment $vault_setting_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationVaultSettings/{vault_setting_name}") $qp)
  let req_body = {"properties": $properties} | compact
  let req_body = if ($input | describe | str starts-with "record") { $input | merge deep ($req_body | default {}) } else { $req_body }
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "put" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" $req_body {query: ({"api-version": $api_version} | compact), body: $req_body}
}

# Gets the list of vCenter registered under the vault.
#
# GET /Subscriptions/{subscriptionId}/resourceGroups/{resourceGroupName}/providers/Microsoft.RecoveryServices/vaults/{resourceName}/replicationvCenters
# operationId: ReplicationvCenters_List
export def "subscriptions-resource-groups-providers-microsoft-recovery-services-vaults-replicationv-centers list" [
  subscription_id: string
  resource_group_name: string
  resource_name: string
  --base-url(-b): string@base-url-completer # API base URL
  --token(-t): string # Auth token
  --auth-scheme(-a): string@auth-scheme-completer # Auth scheme
  --insecure(-k) # Skip TLS verification
  --max-time(-m): duration # Timeout
  --raw(-r) # Fetch as text
  --allow-errors(-e) # Return full response without error handling
  --full(-F) # Return full response record {status, headers, body} while still raising on 4xx/5xx
  --dry-run(-n) # Return the request that would be sent without executing it
  --api-version: string # Client Api Version.
]: nothing -> record<nextLink: string, value: table<properties: record>> {
  let auth = (build-auth $token ($auth_scheme | default "bearer"))
  let base = ($base_url | default $BASE_URL)
  if ($subscription_id | is-empty) { error make --unspanned { msg: "path parameter 'subscriptionId' must be non-empty" } }
  if ($resource_group_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceGroupName' must be non-empty" } }
  if ($resource_name | is-empty) { error make --unspanned { msg: "path parameter 'resourceName' must be non-empty" } }
  let qp = [(serialize-qp "api-version" $api_version "scalar")] | flatten | str join "&"
  let full_url = (build-url $base ({subscription_id: (encode-path-segment $subscription_id), resource_group_name: (encode-path-segment $resource_group_name), resource_name: (encode-path-segment $resource_name)} | format pattern "/Subscriptions/{subscription_id}/resourceGroups/{resource_group_name}/providers/Microsoft.RecoveryServices/vaults/{resource_name}/replicationvCenters") $qp)
  let accept_val = "application/json"
  let auth = ($auth | update headers ($auth.headers | merge {Accept: $accept_val}))
  do-request "get" $full_url $auth $insecure $raw $dry_run $max_time $allow_errors $full "application/json" null {query: ({"api-version": $api_version} | compact), body: null}
}
